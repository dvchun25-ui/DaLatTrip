from __future__ import annotations

import httpx
import pytest

from app.clients.mapbox_client import MapboxClient


@pytest.mark.asyncio
async def test_mapbox_directions_parses_geojson_route() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith(
            "/driving/108.44,11.94;108.45,11.95"
        )
        assert request.url.params["geometries"] == "geojson"
        assert request.url.params["access_token"] == "test-token"
        return httpx.Response(
            200,
            request=request,
            json={
                "routes": [
                    {
                        "distance": 3250,
                        "duration": 840,
                        "geometry": {
                            "coordinates": [
                                [108.44, 11.94],
                                [108.45, 11.95],
                            ]
                        },
                    }
                ]
            },
        )

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        route = await MapboxClient(
            access_token="test-token",
            http_client=http,
        ).get_route(
            [(11.94, 108.44), (11.95, 108.45)],
            "driving",
        )

    assert route.distance_km == 3.25
    assert route.duration_minutes == 14
    assert route.coordinates == [(11.94, 108.44), (11.95, 108.45)]
