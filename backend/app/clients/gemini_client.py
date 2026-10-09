from __future__ import annotations

import asyncio
import json
from typing import Any

import httpx


class GeminiClientError(RuntimeError):
    pass


class GeminiClient:
    _endpoint = "https://generativelanguage.googleapis.com/v1beta/interactions"

    def __init__(
        self,
        *,
        api_key: str,
        model: str,
        http_client: httpx.AsyncClient | None = None,
    ) -> None:
        self._api_key = api_key
        self._model = model
        self._http_client = http_client

    async def generate_structured_json(
        self,
        *,
        system_instruction: str,
        prompt: str,
        schema: dict[str, Any],
    ) -> dict[str, Any]:
        if not self._api_key:
            raise GeminiClientError("GEMINI_API_KEY chưa được cấu hình.")

        owns_client = self._http_client is None
        client = self._http_client or httpx.AsyncClient(timeout=30)
        try:
            response: httpx.Response | None = None
            for attempt in range(3):
                response = await client.post(
                    self._endpoint,
                    headers={
                        "x-goog-api-key": self._api_key,
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": self._model,
                        "system_instruction": system_instruction,
                        "input": prompt,
                        "store": False,
                        "generation_config": {"temperature": 0.1},
                        "response_format": {
                            "type": "text",
                            "mime_type": "application/json",
                            "schema": schema,
                        },
                    },
                )
                should_retry = (
                    response.status_code == 429 or response.status_code >= 500
                )
                if not should_retry or attempt == 2:
                    break
                await asyncio.sleep(0.6 * (attempt + 1))

            if response is None:
                raise GeminiClientError("Gemini không trả về response.")
            response.raise_for_status()
            text = self._extract_output_text(response.json())
            parsed = json.loads(text)
            if not isinstance(parsed, dict):
                raise GeminiClientError("Gemini không trả về JSON object.")
            return parsed
        except (httpx.HTTPError, json.JSONDecodeError, KeyError) as error:
            raise GeminiClientError(
                f"Không thể đọc structured output từ Gemini: {error}"
            ) from error
        finally:
            if owns_client:
                await client.aclose()

    @staticmethod
    def _extract_output_text(payload: dict[str, Any]) -> str:
        for step in reversed(payload.get("steps", [])):
            if step.get("type") != "model_output":
                continue
            texts = [
                content.get("text", "")
                for content in step.get("content", [])
                if content.get("type") == "text"
            ]
            if texts:
                return "".join(texts)
        raise GeminiClientError("Gemini response không có model text output.")
