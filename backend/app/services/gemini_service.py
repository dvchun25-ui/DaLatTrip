from __future__ import annotations

import json
from typing import Any

from app.clients.gemini_client import GeminiClient, GeminiClientError
from app.schemas.ai_trip_parse import AiTripParseResponse
from app.schemas.trip_request import (
    ALLOWED_INTERESTS,
    ALLOWED_PACES,
    ALLOWED_TRANSPORTS,
    REQUIRED_TRIP_FIELDS,
    TripRequestDraftSchema,
    TripRequestSchema,
)
from app.services.trip_text_normalizer import (
    extract_explicit_trip_facts,
    keep_only_explicit_required_fields,
)

SYSTEM_PROMPT = """
Bạn là Trip Request Parser cho ứng dụng DALATTRIP.

Bạn KHÔNG tạo lịch trình, KHÔNG chọn địa điểm, KHÔNG tính khoảng cách,
KHÔNG bịa giá và KHÔNG bịa giờ mở cửa.

Bạn chỉ:
- trích xuất dữ liệu người dùng đã nói;
- chuẩn hóa dữ liệu sang schema được cung cấp;
- xác định thông tin còn thiếu;
- đề xuất câu hỏi bổ sung ngắn gọn bằng tiếng Việt.

Không suy đoán budget, transport hoặc pace nếu người dùng không nói.
Mọi trường bắt buộc chỉ được trả giá trị khi có bằng chứng trong tin nhắn mới
hoặc trong dữ liệu đã thu thập từ các lượt trước.
Có thể suy luận:
- đi với người yêu -> people = 2
- hai người -> people = 2
- gia đình N người -> people = N
- 5 triệu -> totalBudget = 5000000
- 500 nghìn -> totalBudget = 500000
- đi chill -> pace = relaxed
- đi càng nhiều càng tốt -> pace = packed
- đi vừa phải -> pace = balanced
- sống ảo -> checkin
- ăn uống -> food
- cà phê -> cafe
- thiên nhiên -> nature

Category hợp lệ: nature, cafe, food, culture, checkin, relax, adventure, family.
Transport hợp lệ: motorbike, car, taxi, walking.
Pace hợp lệ: relaxed, balanced, packed.
Chỉ trả structured JSON theo schema. Không thêm itinerary hoặc place.
""".strip()

_QUESTIONS = {
    "days": "Bạn muốn đi Đà Lạt trong bao nhiêu ngày (từ 2 đến 5 ngày)?",
    "people": "Chuyến đi có bao nhiêu người?",
    "totalBudget": "Ngân sách dự kiến cho toàn bộ chuyến đi là bao nhiêu?",
    "interests": "Bạn yêu thích loại trải nghiệm nào ở Đà Lạt?",
    "transport": "Bạn muốn di chuyển bằng xe máy, ô tô, taxi hay đi bộ?",
    "pace": "Bạn thích lịch trình thư giãn, cân bằng hay đi nhiều địa điểm?",
}

_INTEREST_ALIASES = {
    "thiên nhiên": "nature",
    "nature": "nature",
    "cà phê": "cafe",
    "cafe": "cafe",
    "coffee": "cafe",
    "ẩm thực": "food",
    "ăn uống": "food",
    "food": "food",
    "văn hóa": "culture",
    "văn hoá": "culture",
    "culture": "culture",
    "check-in": "checkin",
    "checkin": "checkin",
    "sống ảo": "checkin",
    "thư giãn": "relax",
    "relax": "relax",
    "khám phá": "adventure",
    "adventure": "adventure",
    "gia đình": "family",
    "family": "family",
}
_TRANSPORT_ALIASES = {
    "xe máy": "motorbike",
    "motorbike": "motorbike",
    "ô tô": "car",
    "oto": "car",
    "car": "car",
    "taxi": "taxi",
    "đi bộ": "walking",
    "walking": "walking",
}
_PACE_ALIASES = {
    "thư giãn": "relaxed",
    "chill": "relaxed",
    "relaxed": "relaxed",
    "cân bằng": "balanced",
    "vừa phải": "balanced",
    "balanced": "balanced",
    "đi nhiều": "packed",
    "packed": "packed",
}


class GeminiTripService:
    def __init__(self, client: GeminiClient) -> None:
        self._client = client

    async def parse_trip_request(
        self,
        *,
        message: str,
        previous_data: dict[str, Any] | None,
    ) -> AiTripParseResponse:
        prompt = (
            "Dữ liệu đã thu thập từ các lượt trước:\n"
            f"{json.dumps(previous_data or {}, ensure_ascii=False)}\n\n"
            "Tin nhắn mới của người dùng:\n"
            f"{message}\n\n"
            "Hãy trích xuất dữ liệu mới, giữ nguyên dữ liệu cũ và đề xuất câu hỏi "
            "chỉ cho những trường thực sự còn thiếu."
        )
        used_local_fallback = False
        try:
            raw = await self._client.generate_structured_json(
                system_instruction=SYSTEM_PROMPT,
                prompt=prompt,
                schema=_gemini_output_schema(),
            )
        except GeminiClientError:
            # Explicit rules keep the core flow available during transient
            # Gemini quota/outage errors without inventing unknown values.
            raw = {"extractedData": {}}
            used_local_fallback = True
        extracted = raw.get("extractedData") or {}
        explicit = extract_explicit_trip_facts(message)
        extracted = keep_only_explicit_required_fields(
            extracted,
            explicit,
            REQUIRED_TRIP_FIELDS,
        )
        merged = self._merge_and_normalize(previous_data or {}, extracted)
        valid, missing = self._validate(merged)
        questions = [_QUESTIONS[field] for field in missing]

        if missing:
            return AiTripParseResponse(
                status="needs_more_info",
                tripRequest=None,
                collectedData=TripRequestDraftSchema.model_validate(valid),
                missingFields=missing,
                questions=questions,
                message=(
                    "AI đang tạm gián đoạn; mình đã giữ các dữ kiện rõ ràng và "
                    "cần thêm một vài thông tin."
                    if used_local_fallback
                    else "Mình cần thêm một vài thông tin để tạo yêu cầu chuyến đi."
                ),
            )

        trip_request = TripRequestSchema.model_validate(valid)
        return AiTripParseResponse(
            status="ready",
            tripRequest=trip_request,
            collectedData=trip_request,
            missingFields=[],
            questions=[],
            message=(
                "AI đang tạm gián đoạn nhưng dữ liệu rõ ràng đã đủ để tạo lịch trình."
                if used_local_fallback
                else "Đã đủ thông tin để tạo lịch trình."
            ),
        )

    def _merge_and_normalize(
        self,
        previous: dict[str, Any],
        extracted: dict[str, Any],
    ) -> dict[str, Any]:
        previous_draft = TripRequestDraftSchema.model_validate(previous)
        extracted_draft = TripRequestDraftSchema.model_validate(extracted)
        merged = previous_draft.as_camel_dict(exclude_none=True)
        new_values = extracted_draft.as_camel_dict(exclude_none=True)

        old_interests = merged.get("interests", [])
        new_interests = new_values.pop("interests", [])
        if old_interests or new_interests:
            merged["interests"] = list(dict.fromkeys(old_interests + new_interests))

        old_requirements = merged.get("specialRequirements", [])
        new_requirements = new_values.pop("specialRequirements", [])
        if old_requirements or new_requirements:
            merged["specialRequirements"] = list(
                dict.fromkeys(old_requirements + new_requirements)
            )
        merged.update(new_values)

        merged["interests"] = [
            normalized
            for value in merged.get("interests", [])
            if (normalized := _INTEREST_ALIASES.get(str(value).strip().lower()))
        ]
        transport = merged.get("transport")
        if transport is not None:
            merged["transport"] = _TRANSPORT_ALIASES.get(
                str(transport).strip().lower(),
                str(transport).strip().lower(),
            )
        pace = merged.get("pace")
        if pace is not None:
            merged["pace"] = _PACE_ALIASES.get(
                str(pace).strip().lower(),
                str(pace).strip().lower(),
            )
        return merged

    def _validate(
        self,
        data: dict[str, Any],
    ) -> tuple[dict[str, Any], list[str]]:
        valid = TripRequestDraftSchema.model_validate(data).as_camel_dict(
            exclude_none=True
        )
        invalid: set[str] = set()

        if "days" in valid and not 2 <= valid["days"] <= 5:
            valid.pop("days")
            invalid.add("days")
        if "people" in valid and valid["people"] < 1:
            valid.pop("people")
            invalid.add("people")
        if "totalBudget" in valid and valid["totalBudget"] <= 0:
            valid.pop("totalBudget")
            invalid.add("totalBudget")

        interests = [
            value
            for value in valid.get("interests", [])
            if value in ALLOWED_INTERESTS
        ]
        valid["interests"] = list(dict.fromkeys(interests))
        if not interests:
            invalid.add("interests")

        if valid.get("transport") not in ALLOWED_TRANSPORTS:
            valid.pop("transport", None)
            invalid.add("transport")
        if valid.get("pace") not in ALLOWED_PACES:
            valid.pop("pace", None)
            invalid.add("pace")

        missing = [
            field
            for field in REQUIRED_TRIP_FIELDS
            if field in invalid or field not in valid
        ]
        valid.setdefault("startLocation", None)
        valid.setdefault("specialRequirements", [])
        return valid, missing


def _nullable(type_name: str, **extra: Any) -> dict[str, Any]:
    return {"type": [type_name, "null"], **extra}


def _nullable_enum(values: list[str]) -> dict[str, Any]:
    return {
        "anyOf": [
            {"type": "string", "enum": values},
            {"type": "null"},
        ]
    }


def _gemini_output_schema() -> dict[str, Any]:
    trip_properties = {
        "days": _nullable("integer", minimum=2, maximum=5),
        "people": _nullable("integer", minimum=1),
        "totalBudget": _nullable("integer", minimum=1),
        "interests": {
            "type": "array",
            "items": {"type": "string", "enum": sorted(ALLOWED_INTERESTS)},
        },
        "transport": _nullable_enum(sorted(ALLOWED_TRANSPORTS)),
        "pace": _nullable_enum(sorted(ALLOWED_PACES)),
        "startLocation": _nullable("string"),
        "specialRequirements": {
            "type": "array",
            "items": {"type": "string"},
        },
    }
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "extractedData": {
                "type": "object",
                "additionalProperties": False,
                "properties": trip_properties,
                "required": list(trip_properties),
            },
            "questions": {
                "type": "array",
                "items": {"type": "string"},
                "maxItems": 6,
            },
            "message": _nullable("string"),
        },
        "required": ["extractedData", "questions", "message"],
    }
