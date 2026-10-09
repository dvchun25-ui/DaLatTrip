from __future__ import annotations

import json

import httpx
import pytest

from app.clients.gemini_client import GeminiClient


@pytest.mark.asyncio
async def test_retries_transient_503_then_reads_structured_output(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal calls
        calls += 1
        if calls == 1:
            return httpx.Response(503, request=request)
        return httpx.Response(
            200,
            request=request,
            json={
                "steps": [
                    {
                        "type": "model_output",
                        "content": [
                            {
                                "type": "text",
                                "text": json.dumps({"status": "ok"}),
                            }
                        ],
                    }
                ]
            },
        )

    async def no_sleep(_: float) -> None:
        return None

    monkeypatch.setattr("app.clients.gemini_client.asyncio.sleep", no_sleep)
    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http:
        client = GeminiClient(
            api_key="test-key",
            model="test-model",
            http_client=http,
        )
        result = await client.generate_structured_json(
            system_instruction="system",
            prompt="prompt",
            schema={
                "type": "object",
                "properties": {"status": {"type": "string"}},
                "required": ["status"],
            },
        )

    assert calls == 2
    assert result == {"status": "ok"}
