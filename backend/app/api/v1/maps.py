from __future__ import annotations

from functools import lru_cache

from fastapi import APIRouter, Depends, HTTPException, status

from app.clients.mapbox_client import MapboxClient, MapboxClientError
from app.core.config import get_settings
from app.schemas.map_route import MapRouteRequest, MapRouteResponse

router = APIRouter(prefix="/maps", tags=["maps"])


@lru_cache
def get_mapbox_client() -> MapboxClient:
    return MapboxClient(access_token=get_settings().mapbox_access_token)


@router.post(
    "/route",
    response_model=MapRouteResponse,
    response_model_by_alias=True,
)
async def get_route(
    request: MapRouteRequest,
    client: MapboxClient = Depends(get_mapbox_client),
) -> MapRouteResponse:
    coordinates = [
        (coordinate.latitude, coordinate.longitude)
        for coordinate in request.coordinates
    ]
    try:
        route = await client.get_route(coordinates, request.profile)
    except MapboxClientError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error

    return MapRouteResponse(
        coordinates=[
            {"latitude": latitude, "longitude": longitude}
            for latitude, longitude in route.coordinates
        ],
        distanceKm=route.distance_km,
        durationMinutes=route.duration_minutes,
    )
