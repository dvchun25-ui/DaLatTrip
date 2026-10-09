from __future__ import annotations

import json
from pathlib import Path

from fastapi.testclient import TestClient

from app.api.v1.places import get_google_places_service, get_place_catalog
from app.clients.google_places_client import GooglePlacePhoto
from app.main import app
from app.services.place_catalog_service import PlaceCatalogService


class FakeGooglePlacesService:
    def __init__(self, result: GooglePlacePhoto | None) -> None:
        self.result = result
        self.calls: list[str] = []

    async def get_place_photo(
        self,
        google_place_id: str,
    ) -> GooglePlacePhoto | None:
        self.calls.append(google_place_id)
        return self.result


def _catalog(tmp_path: Path) -> PlaceCatalogService:
    path = tmp_path / "places.json"
    path.write_text(
        json.dumps(
            [
                {
                    "id": "custom",
                    "image_url": "https://cdn.example/custom.jpg",
                    "google_place_id": "ignored",
                },
                {
                    "id": "google",
                    "image_url": "",
                    "google_place_id": "google-id",
                },
                {"id": "empty", "image_url": "", "google_place_id": None},
            ]
        ),
        encoding="utf-8",
    )
    return PlaceCatalogService(path)


def test_custom_image_has_priority(tmp_path: Path) -> None:
    google = FakeGooglePlacesService(
        GooglePlacePhoto("https://google.example/photo", None)
    )
    app.dependency_overrides[get_place_catalog] = lambda: _catalog(tmp_path)
    app.dependency_overrides[get_google_places_service] = lambda: google
    try:
        response = TestClient(app).get("/api/v1/places/custom/photo")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()["source"] == "custom"
    assert response.json()["imageUrl"] == "https://cdn.example/custom.jpg"
    assert google.calls == []


def test_google_photo_fallback_and_placeholder(tmp_path: Path) -> None:
    google = FakeGooglePlacesService(
        GooglePlacePhoto("https://google.example/photo", "Photographer")
    )
    app.dependency_overrides[get_place_catalog] = lambda: _catalog(tmp_path)
    app.dependency_overrides[get_google_places_service] = lambda: google
    client = TestClient(app)
    try:
        google_response = client.get("/api/v1/places/google/photo")
        empty_response = client.get("/api/v1/places/empty/photo")
    finally:
        app.dependency_overrides.clear()

    assert google_response.json()["source"] == "google_places"
    assert google_response.json()["imageUrl"] == "https://google.example/photo"
    assert google.calls == ["google-id"]
    assert empty_response.json()["source"] == "placeholder"
    assert empty_response.json()["imageUrl"] is None
