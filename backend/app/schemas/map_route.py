from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class CoordinateSchema(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class MapRouteRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    coordinates: list[CoordinateSchema] = Field(min_length=2, max_length=25)
    profile: Literal["driving", "driving-traffic", "walking", "cycling"] = (
        "driving"
    )


class MapRouteResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    coordinates: list[CoordinateSchema]
    distance_km: float = Field(alias="distanceKm")
    duration_minutes: int = Field(alias="durationMinutes")
