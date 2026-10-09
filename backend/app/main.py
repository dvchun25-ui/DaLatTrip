from __future__ import annotations

import mimetypes
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1.ai import router as ai_router
from app.api.v1.places import router as places_router
from app.api.v1.maps import router as maps_router
from app.core.config import get_settings

settings = get_settings()
mimetypes.add_type("image/webp", ".webp")
backend_root = Path(__file__).resolve().parent.parent
place_image_dir = backend_root / "static" / "place-images"
place_image_dir.mkdir(parents=True, exist_ok=True)

app = FastAPI(
    title="DALATTRIP API",
    version="1.0.0",
    description="Gemini trip parser, Mapbox routing, and place photo proxy.",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.allowed_origins),
    allow_credentials=settings.allowed_origins != ("*",),
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)
app.include_router(ai_router, prefix="/api/v1")
app.include_router(places_router, prefix="/api/v1")
app.include_router(maps_router, prefix="/api/v1")
app.mount(
    "/media/places",
    StaticFiles(directory=place_image_dir),
    name="place-images",
)


@app.get("/")
def root() -> dict[str, str | bool]:
    return {
        "name": "DALATTRIP API",
        "status": "ok",
        "docs": "/docs",
        "health": "/health",
        "geminiConfigured": settings.gemini_configured,
    }


@app.get("/health")
def health() -> dict[str, bool | str]:
    return {
        "status": "ok",
        "geminiConfigured": settings.gemini_configured,
        "googlePlacesConfigured": settings.google_places_configured,
        "mapboxConfigured": settings.mapbox_configured,
    }
