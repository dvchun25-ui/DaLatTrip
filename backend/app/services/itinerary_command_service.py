from __future__ import annotations

import json
import re
import unicodedata
from typing import Any

from app.clients.gemini_client import GeminiClient, GeminiClientError
from app.schemas.itinerary_command import (
    ItineraryCommandContext,
    ItineraryCommandResponse,
)
from app.schemas.trip_request import ALLOWED_INTERESTS


SYSTEM_PROMPT = """
Bạn là bộ phân tích lệnh sửa lịch trình DALATTRIP.
Chỉ chuyển câu người dùng thành MỘT lệnh JSON theo schema.
Không tạo lịch trình, không chọn địa điểm mới, không giải thích và không bịa ID.
placeId chỉ được lấy từ danh sách địa điểm trong context.
Các action hợp lệ: remove_place, add_category, adjust_day_pace,
adjust_day_start, update_budget, replace_outdoor.
Category chỉ dùng danh mục được schema cho phép.
"địa điểm này" nghĩa là selectedPlaceId trong context.
"ngày này" nghĩa là selectedDay trong context.
"nhẹ hơn" chuẩn hóa thành pace=relaxed.
"ngày 1 bắt đầu từ 10g" là adjust_day_start, dayNumber=1,
startMinute=600.
"4 triệu" chuẩn hóa thành totalBudget=4000000.
"đổi địa điểm ngoài trời vì mưa" là replace_outdoor.
""".strip()


class ItineraryCommandError(ValueError):
    pass


class ItineraryCommandService:
    def __init__(self, client: GeminiClient) -> None:
        self._client = client

    async def parse(
        self,
        *,
        message: str,
        context: ItineraryCommandContext,
    ) -> ItineraryCommandResponse:
        local = _parse_locally(message, context)
        raw: dict[str, Any] = {}
        try:
            raw = await self._client.generate_structured_json(
                system_instruction=SYSTEM_PROMPT,
                prompt=(
                    "Context lịch trình hiện tại:\n"
                    f"{json.dumps(context.model_dump(by_alias=True), ensure_ascii=False)}\n\n"
                    f"Câu lệnh người dùng:\n{message}"
                ),
                schema=_output_schema(),
            )
        except GeminiClientError:
            pass

        # Explicit local facts take priority. This prevents a plausible but
        # unsupported value returned by the model from changing the itinerary.
        candidate = local or _sanitize_ai(raw, context)
        if candidate is None:
            raise ItineraryCommandError(
                "Chưa hiểu yêu cầu sửa lịch trình. Hãy dùng một câu lệnh cụ thể."
            )
        return ItineraryCommandResponse.model_validate(candidate)


def _parse_locally(
    message: str,
    context: ItineraryCommandContext,
) -> dict[str, Any] | None:
    text = _fold(message)

    if any(word in text for word in ("bo ", "xoa ", "loai ")):
        place_id = _resolve_place(message, context)
        if place_id is None:
            raise ItineraryCommandError(
                "Hãy chọn địa điểm cần bỏ trước khi gửi câu lệnh."
            )
        return {"action": "remove_place", "placeId": place_id}

    if "them" in text and any(word in text for word in ("cafe", "coffee")):
        return {"action": "add_category", "category": "cafe"}

    if "ngay" in text and any(
        word in text for word in ("nhe hon", "thu gian", "chill")
    ):
        day = _extract_day(text) or context.selected_day
        if day is None:
            raise ItineraryCommandError("Hãy chọn ngày cần điều chỉnh.")
        return {
            "action": "adjust_day_pace",
            "dayNumber": day,
            "pace": "relaxed",
        }

    if "ngay" in text and any(
        word in text for word in ("bat dau", "tu luc", "khoi hanh")
    ):
        day = _extract_day(text) or context.selected_day
        start_minute = _extract_start_minute(text)
        if day is None or start_minute is None:
            raise ItineraryCommandError(
                "Hãy ghi rõ ngày và giờ bắt đầu, ví dụ: ngày 1 bắt đầu từ 10g."
            )
        return {
            "action": "adjust_day_start",
            "dayNumber": day,
            "startMinute": start_minute,
        }

    if any(word in text for word in ("ngan sach", "trieu", "nghin", "k")):
        budget = _extract_money(text)
        if budget is not None and any(
            word in text for word in ("giam", "doi", "ngan sach")
        ):
            return {"action": "update_budget", "totalBudget": budget}

    if "mua" in text and any(
        word in text for word in ("ngoai troi", "ngoai troi", "doi")
    ):
        return {
            "action": "replace_outdoor",
            "dayNumber": _extract_day(text) or context.selected_day,
        }
    return None


def _sanitize_ai(
    raw: dict[str, Any],
    context: ItineraryCommandContext,
) -> dict[str, Any] | None:
    action = raw.get("action")
    if action == "remove_place":
        known_ids = {place.id for place in context.places}
        place_id = raw.get("placeId")
        if place_id in known_ids:
            return {"action": action, "placeId": place_id}
        return None
    if action == "add_category" and raw.get("category") in ALLOWED_INTERESTS:
        return {"action": action, "category": raw["category"]}
    if action == "adjust_day_pace" and raw.get("pace") in {
        "relaxed",
        "balanced",
        "packed",
    }:
        return {
            "action": action,
            "dayNumber": raw.get("dayNumber") or context.selected_day,
            "pace": raw["pace"],
        }
    if action == "adjust_day_start":
        day = raw.get("dayNumber") or context.selected_day
        start_minute = raw.get("startMinute")
        if day and isinstance(start_minute, int) and 360 <= start_minute <= 960:
            return {
                "action": action,
                "dayNumber": day,
                "startMinute": start_minute,
            }
    if action == "update_budget" and isinstance(raw.get("totalBudget"), int):
        if raw["totalBudget"] > 0:
            return {"action": action, "totalBudget": raw["totalBudget"]}
    if action == "replace_outdoor":
        return {
            "action": action,
            "dayNumber": raw.get("dayNumber") or context.selected_day,
        }
    return None


def _resolve_place(
    message: str,
    context: ItineraryCommandContext,
) -> str | None:
    text = _fold(message)
    if any(word in text for word in ("nay", "đang chon")):
        return context.selected_place_id
    matches = [place.id for place in context.places if _fold(place.name) in text]
    if len(matches) == 1:
        return matches[0]
    return context.selected_place_id


def _extract_day(text: str) -> int | None:
    match = re.search(r"ngay\s*(\d+)", text)
    return int(match.group(1)) if match else None


def _extract_start_minute(text: str) -> int | None:
    match = re.search(
        r"(?:bat dau|tu luc|khoi hanh|tu)\D{0,12}(\d{1,2})"
        r"(?:\s*(?:g|gio|:)\s*(\d{1,2})?)?",
        text,
    )
    if not match:
        return None
    hour = int(match.group(1))
    minute = int(match.group(2) or 0)
    value = hour * 60 + minute
    return value if 360 <= value <= 960 and minute < 60 else None


def _extract_money(text: str) -> int | None:
    match = re.search(r"(\d+(?:[.,]\d+)?)\s*(trieu|nghin|k)\b", text)
    if not match:
        match = re.search(r"ngan sach[^\d]*(\d+(?:[.,]\d+)?)", text)
        if not match:
            return None
    amount = float(match.group(1).replace(",", "."))
    unit = match.group(2) if match.lastindex and match.lastindex >= 2 else None
    multiplier = 1_000_000 if unit == "trieu" else 1_000 if unit in {"nghin", "k"} else 1
    value = int(amount * multiplier)
    return value if value > 0 else None


def _fold(value: str) -> str:
    normalized = unicodedata.normalize("NFD", value.lower())
    return "".join(char for char in normalized if unicodedata.category(char) != "Mn").replace("đ", "d")


def _nullable(type_name: str, **extra: Any) -> dict[str, Any]:
    return {"type": [type_name, "null"], **extra}


def _output_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "action": {
                "type": "string",
                "enum": [
                    "remove_place",
                    "add_category",
                    "adjust_day_pace",
                    "adjust_day_start",
                    "update_budget",
                    "replace_outdoor",
                ],
            },
            "placeId": _nullable("string"),
            "category": {
                "anyOf": [
                    {"type": "string", "enum": sorted(ALLOWED_INTERESTS)},
                    {"type": "null"},
                ]
            },
            "dayNumber": _nullable("integer", minimum=1),
            "pace": {
                "anyOf": [
                    {"type": "string", "enum": ["relaxed", "balanced", "packed"]},
                    {"type": "null"},
                ]
            },
            "totalBudget": _nullable("integer", minimum=1),
            "startMinute": _nullable("integer", minimum=360, maximum=960),
        },
        "required": [
            "action",
            "placeId",
            "category",
            "dayNumber",
            "pace",
            "totalBudget",
            "startMinute",
        ],
    }
