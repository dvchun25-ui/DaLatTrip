from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


ItineraryAction = Literal[
    "remove_place",
    "add_category",
    "adjust_day_pace",
    "adjust_day_start",
    "update_budget",
    "replace_outdoor",
]


class ItineraryContextPlace(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    name: str
    day_number: int = Field(alias="dayNumber", ge=1)
    indoor: bool


class ItineraryCommandContext(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    selected_place_id: str | None = Field(default=None, alias="selectedPlaceId")
    selected_day: int | None = Field(default=None, alias="selectedDay", ge=1)
    places: list[ItineraryContextPlace] = Field(default_factory=list)


class ItineraryCommandRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    context: ItineraryCommandContext = Field(
        default_factory=ItineraryCommandContext
    )


class ItineraryCommandResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    action: ItineraryAction
    place_id: str | None = Field(default=None, alias="placeId")
    category: str | None = None
    day_number: int | None = Field(default=None, alias="dayNumber")
    pace: Literal["relaxed", "balanced", "packed"] | None = None
    total_budget: int | None = Field(default=None, alias="totalBudget", ge=1)
    start_minute: int | None = Field(
        default=None,
        alias="startMinute",
        ge=360,
        le=960,
    )
