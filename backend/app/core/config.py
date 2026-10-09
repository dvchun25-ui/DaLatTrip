from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from app.core.env import load_env_file

BACKEND_ROOT = Path(__file__).resolve().parents[2]
PROJECT_ROOT = BACKEND_ROOT.parent
load_env_file(BACKEND_ROOT / ".env")


@dataclass(frozen=True)
class Settings:
    gemini_api_key: str
    gemini_model: str
    google_places_api_key: str
    mapbox_access_token: str
    allowed_origins: tuple[str, ...]
    dataset_path: Path

    @property
    def gemini_configured(self) -> bool:
        return bool(self.gemini_api_key)

    @property
    def google_places_configured(self) -> bool:
        return bool(self.google_places_api_key)

    @property
    def mapbox_configured(self) -> bool:
        return bool(self.mapbox_access_token)


@lru_cache
def get_settings() -> Settings:
    origins = tuple(
        item.strip()
        for item in os.getenv("ALLOWED_ORIGINS", "*").split(",")
        if item.strip()
    )
    return Settings(
        gemini_api_key=os.getenv("GEMINI_API_KEY", "").strip(),
        gemini_model=os.getenv("GEMINI_MODEL", "gemini-3.8-flash").strip(),
        google_places_api_key=os.getenv("GOOGLE_PLACES_API_KEY", "").strip(),
        mapbox_access_token=os.getenv("MAPBOX_ACCESS_TOKEN", "").strip(),
        allowed_origins=origins or ("*",),
        dataset_path=PROJECT_ROOT / "assets" / "data" / "dalat_places.json",
    )
