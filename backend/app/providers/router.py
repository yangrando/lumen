from typing import Any, Dict, List

from .base import AIProvider, AIProviderError


class AIFallbackRouter:
    def __init__(self, providers: List[AIProvider]):
        self.providers = providers

    async def generate(self, prompt: str, params: Dict[str, Any]) -> str:
        last_error: AIProviderError | None = None
        for provider in self.providers:
            try:
                return await provider.generate(prompt, params)
            except AIProviderError as exc:
                last_error = exc
                # Fallback only on rate-limit/5xx or missing config
                if exc.status_code in {429, 500, 502, 503, 504} or exc.status_code is None:
                    continue
                raise
        if last_error:
            raise last_error
        raise AIProviderError("No AI providers configured")
