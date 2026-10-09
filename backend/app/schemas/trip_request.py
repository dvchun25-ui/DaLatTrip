from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field

ALLOWED_INTERESTS = {
    "nature",
    "cafe",
    "food",
    "culture",
    "checkin",
    "relax",
    "adventure",
    "family",
}
ALLOWED_TRANSPORTS = {"motorbike", "car", "taxi", "walking"}
ALLOWED_PACES = {"relaxed", "balanced", "packed"}
REQUIRED_TRIP_FIELDS = (
    "days",
    "people",
    "totalBudget",
    "interests",
    "transport",
    "pace",
)


class TripRequestDraftSchema(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    days: int | None = None
    people: int | None = None
    total_budget: int | None = Field(default=None, alias="totalBudget")
    interests: list[str] = Field(default_factory=list)
    transport: str | None = None
    pace: str | None = None
    start_location: str | None = Field(default=None, alias="startLocation")
    special_requirements: list[str] = Field(
        default_factory=list,
        alias="specialRequirements",
    )

    def as_camel_dict(self, *, exclude_none: bool = False) -> dict[str, Any]:
        return self.model_dump(by_alias=True, exclude_none=exclude_none)


class TripRequestSchema(TripRequestDraftSchema):
    days: int
    people: int
    total_budget: int = Field(alias="totalBudget")
    interests: list[str]
    transport: str
    pace: str
