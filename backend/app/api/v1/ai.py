from __future__ import annotations

from functools import lru_cache

from fastapi import APIRouter, Depends, HTTPException, status

from app.clients.gemini_client import GeminiClient, GeminiClientError
from app.core.config import get_settings
from app.schemas.ai_trip_parse import AiTripParseRequest, AiTripParseResponse
from app.schemas.itinerary_command import (
    ItineraryCommandRequest,
    ItineraryCommandResponse,
)
from app.services.gemini_service import GeminiTripService
from app.services.itinerary_command_service import (
    ItineraryCommandError,
    ItineraryCommandService,
)

router = APIRouter(prefix="/ai", tags=["ai"])


@lru_cache
def get_ai_trip_service() -> GeminiTripService:
    settings = get_settings()
    return GeminiTripService(
        GeminiClient(
            api_key=settings.gemini_api_key,
            model=settings.gemini_model,
        )
    )


@lru_cache
def get_itinerary_command_service() -> ItineraryCommandService:
    settings = get_settings()
    return ItineraryCommandService(
        GeminiClient(
            api_key=settings.gemini_api_key,
            model=settings.gemini_model,
        )
    )


@router.post(
    "/parse-trip-request",
    response_model=AiTripParseResponse,
    response_model_by_alias=True,
)
async def parse_trip_request(
    request: AiTripParseRequest,
    service: GeminiTripService = Depends(get_ai_trip_service),
) -> AiTripParseResponse:
    try:
        return await service.parse_trip_request(
            message=request.message,
            previous_data=request.previous_data,
        )
    except GeminiClientError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error


@router.post(
    "/parse-itinerary-command",
    response_model=ItineraryCommandResponse,
    response_model_by_alias=True,
)
async def parse_itinerary_command(
    request: ItineraryCommandRequest,
    service: ItineraryCommandService = Depends(get_itinerary_command_service),
) -> ItineraryCommandResponse:
    try:
        return await service.parse(
            message=request.message,
            context=request.context,
        )
    except ItineraryCommandError as error:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(error),
        ) from error
