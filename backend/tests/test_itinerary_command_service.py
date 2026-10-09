from __future__ import annotations

from typing import Any

import pytest

from app.clients.gemini_client import GeminiClientError
from app.schemas.itinerary_command import ItineraryCommandContext
from app.services.itinerary_command_service import ItineraryCommandService


class UnavailableClient:
    async def generate_structured_json(
        self,
        *,
        system_instruction: str,
        prompt: str,
        schema: dict[str, Any],
    ) -> dict[str, Any]:
        assert "Chỉ chuyển" in system_instruction
        raise GeminiClientError("offline")


def _context() -> ItineraryCommandContext:
    return ItineraryCommandContext.model_validate(
        {
            "selectedPlaceId": "ga_da_lat",
            "selectedDay": 2,
            "places": [
                {
                    "id": "ga_da_lat",
                    "name": "Ga Đà Lạt",
                    "dayNumber": 2,
                    "indoor": False,
                }
            ],
        }
    )


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("message", "expected"),
    [
        ("Bỏ địa điểm này", {"action": "remove_place", "placeId": "ga_da_lat"}),
        ("Thêm một quán cafe", {"action": "add_category", "category": "cafe"}),
        (
            "Ngày 2 đi nhẹ hơn",
            {"action": "adjust_day_pace", "dayNumber": 2, "pace": "relaxed"},
        ),
        (
            "Tôi muốn nghỉ ngơi ngày 1 bắt đầu từ 10g",
            {
                "action": "adjust_day_start",
                "dayNumber": 1,
                "startMinute": 600,
            },
        ),
        (
            "Giảm ngân sách xuống 4 triệu",
            {"action": "update_budget", "totalBudget": 4_000_000},
        ),
        (
            "Đổi địa điểm ngoài trời vì trời mưa",
            {"action": "replace_outdoor", "dayNumber": 2},
        ),
    ],
)
async def test_five_supported_commands_work_during_ai_outage(
    message: str,
    expected: dict[str, Any],
) -> None:
    result = await ItineraryCommandService(UnavailableClient()).parse(  # type: ignore[arg-type]
        message=message,
        context=_context(),
    )
    payload = result.model_dump(by_alias=True, exclude_none=True)
    assert payload == expected


@pytest.mark.asyncio
async def test_remove_never_accepts_an_unknown_place_id() -> None:
    context = _context().model_copy(update={"selected_place_id": None})
    with pytest.raises(ValueError, match="chọn địa điểm"):
        await ItineraryCommandService(UnavailableClient()).parse(  # type: ignore[arg-type]
            message="Bỏ địa điểm này",
            context=context,
        )
