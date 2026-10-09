from __future__ import annotations

from functools import lru_cache

from fastapi import APIRouter, Depends, HTTPException, status

from app.clients.google_places_client import GooglePlacesClient
from app.core.config import get_settings
from app.schemas.place_photo import PlacePhotoResponse
from app.services.google_places_service import GooglePlacesService
from app.services.place_catalog_service import PlaceCatalogService

router = APIRouter(prefix="/places", tags=["places"])


@lru_cache
def get_place_catalog() -> PlaceCatalogService:
    return PlaceCatalogService(get_settings().dataset_path)


@lru_cache
def get_google_places_service() -> GooglePlacesService:
    settings = get_settings()
    return GooglePlacesService(
        GooglePlacesClient(api_key=settings.google_places_api_key)
    )


@router.get(
    "/{place_id}/photo",
    response_model=PlacePhotoResponse,
    response_model_by_alias=True,
)
async def get_place_photo(
    place_id: str,
    catalog: PlaceCatalogService = Depends(get_place_catalog),
    google_service: GooglePlacesService = Depends(get_google_places_service),
) -> PlacePhotoResponse:
    place = catalog.get_place(place_id)
    if place is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy địa điểm.",
        )

    custom_url = str(place.get("image_url") or "").strip()
    if custom_url:
        return PlacePhotoResponse(
            placeId=place_id,
            imageUrl=custom_url,
            source="custom",
        )

    google_place_id = str(place.get("google_place_id") or "").strip()
    if google_place_id:
        photo = await google_service.get_place_photo(google_place_id)
        if photo is not None:
            return PlacePhotoResponse(
                placeId=place_id,
                imageUrl=photo.image_url,
                source="google_places",
                attribution=photo.attribution,
            )

    return PlacePhotoResponse(
        placeId=place_id,
        imageUrl=None,
        source="placeholder",
    )
