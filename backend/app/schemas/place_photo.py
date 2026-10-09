from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class PlacePhotoResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    place_id: str = Field(alias="placeId")
    image_url: str | None = Field(default=None, alias="imageUrl")
    source: Literal["custom", "google_places", "placeholder"]
    attribution: str | None = None
