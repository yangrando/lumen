from typing import Any, Dict
import logging

import httpx

from ..config import settings
from .base import AIProviderError


class GeminiProvider:
    name = "gemini"
    logger = logging.getLogger("lumen.gemini")

    async def generate(self, prompt: str, params: Dict[str, Any]) -> str:
        if not settings.gemini_api_key:
            raise AIProviderError("GEMINI_API_KEY not configured")

        temperature = params.get("temperature", 0.7)
        max_tokens = params.get("max_tokens", 800)
        task = params.get("task")

        url = f"{settings.gemini_base_url}/models/{settings.gemini_model}:generateContent"
        headers = {
            "x-goog-api-key": settings.gemini_api_key,
            "Content-Type": "application/json",
        }

        generation_config: Dict[str, Any] = {
            "temperature": temperature,
            "maxOutputTokens": max_tokens,
        }

        if task == "generate_phrases":
            generation_config["responseMimeType"] = "application/json"
            generation_config["responseSchema"] = {
                "type": "ARRAY",
                "items": {
                    "type": "OBJECT",
                    "properties": {
                        "text": {"type": "STRING"},
                        "translation": {"type": "STRING"},
                        "category": {"type": "STRING"},
                        "difficulty": {"type": "STRING"},
                    },
                    "required": ["text", "translation", "category", "difficulty"],
                },
            }

        body = {
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"text": prompt}
                    ],
                }
            ],
            "generationConfig": generation_config,
        }

        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(url, json=body, headers=headers)

        if resp.status_code < 200 or resp.status_code >= 300:
            self.logger.error(
                "gemini_error status=%s body=%s",
                resp.status_code,
                resp.text[:1000],
            )
            raise AIProviderError(resp.text, status_code=resp.status_code)

        data = resp.json()
        try:
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except Exception as exc:
            self.logger.error("gemini_parse_error body=%s", resp.text[:1000])
            raise AIProviderError(f"Invalid Gemini response format: {exc}") from exc
