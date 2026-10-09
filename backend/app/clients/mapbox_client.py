from __future__ import annotations

from dataclasses import dataclass

import httpx


class MapboxClientError(RuntimeError):
    pass


@dataclass(frozen=True)
class MapboxRoute:
    coordinates: list[tuple[float, float]]
    distance_km: float
    duration_minutes: int


class MapboxClient:
    _base_url = "https://api.mapbox.com/directions/v5/mapbox"

    def __init__(
        self,
        *,
        access_token: str,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self._access_token = access_token
        self._http_client = http_client

    async def get_route(
        self,
        coordinates: list[tuple[float, float]],
        profile: str,
    ) -> MapboxRoute:
        if not self._access_token:
            raise MapboxClientError("Mapbox chưa được cấu hình.")
        if not 2 <= len(coordinates) <= 25:
            raise MapboxClientError("Tuyến đường cần từ 2 đến 25 tọa độ.")

        coordinate_path = ";".join(
            f"{longitude},{latitude}" for latitude, longitude in coordinates
        )
        owns_client = self._http_client is None
        client = self._http_client or httpx.AsyncClient(timeout=20)
        try:
            response = await client.get(
                f"{self._base_url}/{profile}/{coordinate_path}",
                params={
                    "access_token": self._access_token,
                    "geometries": "geojson",
                    "overview": "full",
                    "steps": "false",
                },
            )
            response.raise_for_status()
            routes = response.json().get("routes", [])
            if not routes:
                raise MapboxClientError("Mapbox không tìm thấy tuyến đường.")
            route = routes[0]
            geometry = route.get("geometry", {}).get("coordinates", [])
            if not geometry:
                raise MapboxClientError("Mapbox không trả về hình dạng tuyến đường.")
            return MapboxRoute(
                coordinates=[
                    (float(point[1]), float(point[0])) for point in geometry
                ],
                distance_km=round(float(route.get("distance", 0)) / 1000, 2),
                duration_minutes=max(
                    1,
                    round(float(route.get("duration", 0)) / 60),
                ),
            )
        except MapboxClientError:
            raise
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as error:
            raise MapboxClientError(f"Mapbox Directions thất bại: {error}") from error
        finally:
            if owns_client:
                await client.aclose()
