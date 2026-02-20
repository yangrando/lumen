from typing import Any, Dict
import logging

import httpx

from ..config import settings
from .base import AIProviderError


class OpenAIProvider:
    name = "openai"
    logger = logging.getLogger("lumen.openai")

    async def generate(self, prompt: str, params: Dict[str, Any]) -> str:
        if not settings.openai_api_key:
            raise AIProviderError("OPENAI_API_KEY not configured")

        temperature = params.get("temperature", 0.7)
        max_tokens = params.get("max_tokens", 800)

        body = {
            "model": settings.openai_model,
            "input": [
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": prompt}
                    ],
                }
            ],
            "temperature": temperature,
            "max_output_tokens": max_tokens,
        }

        headers = {
            "Authorization": f"Bearer {settings.openai_api_key}",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(settings.openai_base_url, json=body, headers=headers)

        if resp.status_code < 200 or resp.status_code >= 300:
            self.logger.error(
                "openai_error status=%s body=%s",
                resp.status_code,
                resp.text[:1000],
            )
            raise AIProviderError(resp.text, status_code=resp.status_code)

        data = resp.json()
        try:
            return data["output"][0]["content"][0]["text"]
        except Exception as exc:
            self.logger.error("openai_parse_error body=%s", resp.text[:1000])
            raise AIProviderError(f"Invalid OpenAI response format: {exc}") from exc
