from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class PlaceCatalogService:
    def __init__(self, dataset_path: Path) -> None:
        self._dataset_path = dataset_path
        self._cache: dict[str, dict[str, Any]] | None = None

    def get_place(self, place_id: str) -> dict[str, Any] | None:
        if self._cache is None:
            records = json.loads(self._dataset_path.read_text(encoding="utf-8"))
            self._cache = {
                str(record.get("id", "")): record
                for record in records
                if record.get("id")
            }
        return self._cache.get(place_id)
