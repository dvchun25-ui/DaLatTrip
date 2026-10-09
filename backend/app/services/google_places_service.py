from __future__ import annotations

from app.clients.google_places_client import (
    GooglePlacePhoto,
    GooglePlacesClient,
    GooglePlacesClientError,
)


class GooglePlacesService:
    def __init__(self, client: GooglePlacesClient) -> None:
        self._client = client

    async def get_place_photo(
        self,
        google_place_id: str,
    ) -> GooglePlacePhoto | None:
        try:
            return await self._client.get_photo(google_place_id)
        except GooglePlacesClientError:
            return None
