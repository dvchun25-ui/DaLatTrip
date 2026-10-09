from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.trip_request import TripRequestDraftSchema, TripRequestSchema


class AiTripParseRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    message: str = Field(min_length=1, max_length=2000)
    previous_data: dict[str, Any] | None = Field(
        default=None,
        alias="previousData",
    )


class AiTripParseResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    status: Literal["needs_more_info", "ready"]
    trip_request: TripRequestSchema | None = Field(
        default=None,
        alias="tripRequest",
    )
    collected_data: TripRequestDraftSchema = Field(alias="collectedData")
    missing_fields: list[str] = Field(
        default_factory=list,
        alias="missingFields",
    )
    questions: list[str] = Field(default_factory=list)
    message: str | None = None
