from __future__ import annotations

from typing import Any

import pytest

from app.clients.gemini_client import GeminiClientError
from app.services.gemini_service import GeminiTripService
from app.services.trip_text_normalizer import extract_explicit_trip_facts


class FakeGeminiClient:
    def __init__(self, outputs: list[dict[str, Any]]) -> None:
        self.outputs = list(outputs)
        self.prompts: list[str] = []

    async def generate_structured_json(
        self,
        *,
        system_instruction: str,
        prompt: str,
        schema: dict[str, Any],
    ) -> dict[str, Any]:
        self.prompts.append(prompt)
        assert "KHÔNG tạo lịch trình" in system_instruction
        assert "additionalProperties" in schema
        return self.outputs.pop(0)


class UnavailableGeminiClient:
    async def generate_structured_json(
        self,
        *,
        system_instruction: str,
        prompt: str,
        schema: dict[str, Any],
    ) -> dict[str, Any]:
        raise GeminiClientError("temporary outage")


@pytest.mark.asyncio
async def test_missing_fields_then_previous_data_is_preserved() -> None:
    client = FakeGeminiClient(
        [
            {
                "extractedData": {
                    "days": 3,
                    "people": 2,
                    "totalBudget": None,
                    "interests": ["nature", "cafe"],
                    "transport": None,
                    "pace": None,
                    "startLocation": None,
                    "specialRequirements": [],
                },
                "questions": [],
                "message": None,
            },
            {
                "extractedData": {
                    "days": None,
                    "people": None,
                    "totalBudget": 5_000_000,
                    "interests": [],
                    "transport": "motorbike",
                    "pace": "relaxed",
                    "startLocation": None,
                    "specialRequirements": [],
                },
                "questions": [],
                "message": None,
            },
        ]
    )
    service = GeminiTripService(client)  # type: ignore[arg-type]

    first = await service.parse_trip_request(
        message=(
            "Đi Đà Lạt 3 ngày với người yêu, thích thiên nhiên và cà phê."
        ),
        previous_data=None,
    )
    assert first.status == "needs_more_info"
    assert first.collected_data.days == 3
    assert first.collected_data.people == 2
    assert set(first.collected_data.interests) == {"nature", "cafe"}
    assert first.missing_fields == ["totalBudget", "transport", "pace"]
    assert len(first.questions) == 3
    assert first.trip_request is None
    first_payload = first.model_dump(by_alias=True)
    assert first_payload["collectedData"]["totalBudget"] is None
    assert first_payload["collectedData"]["transport"] is None
    assert first_payload["collectedData"]["pace"] is None

    second = await service.parse_trip_request(
        message="Ngân sách 5 triệu, đi xe máy, muốn lịch thư giãn.",
        previous_data=first.collected_data.as_camel_dict(exclude_none=True),
    )
    assert second.status == "ready"
    assert second.trip_request is not None
    assert second.trip_request.days == 3
    assert second.trip_request.people == 2
    assert second.trip_request.total_budget == 5_000_000
    assert second.trip_request.interests == ["nature", "cafe"]
    assert second.trip_request.transport == "motorbike"
    assert second.trip_request.pace == "relaxed"
    assert second.missing_fields == []


@pytest.mark.asyncio
async def test_invalid_ai_values_are_rejected_and_no_itinerary_is_returned() -> None:
    client = FakeGeminiClient(
        [
            {
                "extractedData": {
                    "days": 10,
                    "people": 0,
                    "totalBudget": -1,
                    "interests": ["unknown"],
                    "transport": "plane",
                    "pace": "extreme",
                    "startLocation": None,
                    "specialRequirements": [],
                },
                "questions": [],
                "message": None,
            }
        ]
    )
    result = await GeminiTripService(client).parse_trip_request(  # type: ignore[arg-type]
        message="Tạo chuyến đi",
        previous_data=None,
    )
    payload = result.model_dump(by_alias=True)

    assert result.status == "needs_more_info"
    assert set(result.missing_fields) == {
        "days",
        "people",
        "totalBudget",
        "interests",
        "transport",
        "pace",
    }
    assert "itinerary" not in payload
    assert payload["tripRequest"] is None


@pytest.mark.asyncio
async def test_vietnamese_aliases_are_normalized_to_dataset_values() -> None:
    client = FakeGeminiClient(
        [
            {
                "extractedData": {
                    "days": 2,
                    "people": 2,
                    "totalBudget": 5_000_000,
                    "interests": ["thiên nhiên", "cà phê", "không tồn tại"],
                    "transport": "xe máy",
                    "pace": "thư giãn",
                    "startLocation": None,
                    "specialRequirements": [],
                },
                "questions": [],
                "message": None,
            }
        ]
    )

    result = await GeminiTripService(client).parse_trip_request(  # type: ignore[arg-type]
        message=(
            "Tôi đi hai người trong 2 ngày, ngân sách 5 triệu, thích thiên "
            "nhiên và cà phê, đi xe máy, lịch thư giãn."
        ),
        previous_data=None,
    )

    assert result.status == "ready"
    assert result.trip_request is not None
    assert result.trip_request.people == 2
    assert result.trip_request.total_budget == 5_000_000
    assert result.trip_request.interests == ["nature", "cafe"]
    assert result.trip_request.transport == "motorbike"
    assert result.trip_request.pace == "relaxed"


@pytest.mark.asyncio
async def test_example_rejects_plausible_but_unsupported_ai_values() -> None:
    client = FakeGeminiClient(
        [
            {
                "extractedData": {
                    "days": 3,
                    "people": 2,
                    "totalBudget": 9_000_000,
                    "interests": ["nature", "cafe"],
                    "transport": "taxi",
                    "pace": "packed",
                    "startLocation": None,
                    "specialRequirements": [],
                },
                "questions": [],
                "message": None,
            }
        ]
    )

    result = await GeminiTripService(client).parse_trip_request(  # type: ignore[arg-type]
        message="Tôi đi với người yêu 3 ngày, thích thiên nhiên và cafe.",
        previous_data=None,
    )
    payload = result.model_dump(by_alias=True)["collectedData"]

    assert payload["days"] == 3
    assert payload["people"] == 2
    assert payload["totalBudget"] is None
    assert payload["interests"] == ["nature", "cafe"]
    assert payload["transport"] is None
    assert payload["pace"] is None
    assert result.missing_fields == ["totalBudget", "transport", "pace"]


def test_rule_normalizer_handles_vietnamese_numbers_without_false_transport() -> None:
    assert extract_explicit_trip_facts(
        "Đi hai người, bốn ngày, ngân sách 5 triệu"
    ) == {
        "days": 4,
        "people": 2,
        "totalBudget": 5_000_000,
    }


@pytest.mark.asyncio
async def test_local_fallback_keeps_known_values_when_gemini_is_unavailable() -> None:
    result = await GeminiTripService(  # type: ignore[arg-type]
        UnavailableGeminiClient()
    ).parse_trip_request(
        message="Tôi đi với người yêu 3 ngày, thích thiên nhiên và cafe.",
        previous_data=None,
    )

    assert result.status == "needs_more_info"
    assert result.collected_data.days == 3
    assert result.collected_data.people == 2
    assert result.collected_data.total_budget is None
    assert result.collected_data.interests == ["nature", "cafe"]
    assert result.collected_data.transport is None
    assert result.collected_data.pace is None
    assert result.missing_fields == ["totalBudget", "transport", "pace"]
    assert "tạm gián đoạn" in (result.message or "")
