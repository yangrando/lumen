from typing import Protocol, Any, Dict


class AIProviderError(Exception):
    def __init__(self, message: str, status_code: int | None = None):
        super().__init__(message)
        self.status_code = status_code


class AIProvider(Protocol):
    name: str

    async def generate(self, prompt: str, params: Dict[str, Any]) -> str:
        ...
