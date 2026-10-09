from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx


class GooglePlacesClientError(RuntimeError):
    pass


@dataclass(frozen=True)
class GooglePlacePhoto:
    image_url: str
    attribution: str | None


class GooglePlacesClient:
    _base_url = "https://places.googleapis.com/v1"

    def __init__(
        self,
        *,
        api_key: str,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self._api_key = api_key
        self._http_client = http_client

    async def get_photo(self, google_place_id: str) -> GooglePlacePhoto | None:
        if not self._api_key or not google_place_id.strip():
            return None

        owns_client = self._http_client is None
        client = self._http_client or httpx.AsyncClient(timeout=20)
        headers = {
            "X-Goog-Api-Key": self._api_key,
            "X-Goog-FieldMask": "photos",
        }
        try:
            details = await client.get(
                f"{self._base_url}/places/{google_place_id}",
                headers=headers,
            )
            details.raise_for_status()
            photos = details.json().get("photos", [])
            if not photos:
                return None
            photo = photos[0]
            photo_name = photo.get("name")
            if not photo_name:
                return None

            media = await client.get(
                f"{self._base_url}/{photo_name}/media",
                headers={"X-Goog-Api-Key": self._api_key},
                params={"maxWidthPx": 1200, "skipHttpRedirect": "true"},
            )
            media.raise_for_status()
            image_url = media.json().get("photoUri")
            if not image_url:
                return None
            return GooglePlacePhoto(
                image_url=image_url,
                attribution=self._first_attribution(photo),
            )
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as error:
            raise GooglePlacesClientError(
                f"Google Places Photo request thất bại: {error}"
            ) from error
        finally:
            if owns_client:
                await client.aclose()

    @staticmethod
    def _first_attribution(photo: dict[str, Any]) -> str | None:
        attributions = photo.get("authorAttributions", [])
        if not attributions:
            return None
        first = attributions[0]
        return first.get("displayName") or first.get("uri")
