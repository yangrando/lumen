import json
import logging
import time
import uuid
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
from typing import Any, Dict

from .config import settings, get_provider_order_for_task
from .auth import login_with_google, login_with_apple, AuthError
from .providers.openai import OpenAIProvider
from .providers.gemini import GeminiProvider
from .providers.router import AIFallbackRouter
from .providers.base import AIProviderError

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("lumen")

app = FastAPI(title="Lumen Backend", version="0.1.0")


# Providers can be expanded here later (Anthropic, Gemini, etc.)
PROVIDER_REGISTRY = {
    "openai": OpenAIProvider(),
    "gemini": GeminiProvider(),
}


def build_provider_chain(provider_names: list[str]) -> AIFallbackRouter:
    providers = []
    for name in provider_names:
        provider = PROVIDER_REGISTRY.get(name)
        if provider:
            providers.append(provider)
    return AIFallbackRouter(providers)


class AuthRequest(BaseModel):
    id_token: str


class GenerateRequest(BaseModel):
    prompt: str = Field(min_length=1)
    temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: int = Field(default=800, ge=1, le=4000)
    task: str | None = None
    meta: Dict[str, Any] | None = None


def _strip_code_fences(text: str) -> str:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.replace("```json", "").replace("```", "").strip()
    return cleaned


def _validate_phrases_json(text: str) -> str:
    cleaned = _strip_code_fences(text)
    data = json.loads(cleaned)
    if not isinstance(data, list):
        raise ValueError("Expected a JSON array")
    for item in data:
        if not isinstance(item, dict):
            raise ValueError("Each item must be an object")
        for key in ("text", "translation", "category", "difficulty"):
            if key not in item or not isinstance(item[key], str) or not item[key].strip():
                raise ValueError(f"Missing or invalid key: {key}")
    return json.dumps(data, ensure_ascii=False)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
    start = time.perf_counter()
    try:
        response = await call_next(request)
    except Exception:
        logger.exception(
            "request_failed method=%s path=%s request_id=%s",
            request.method,
            request.url.path,
            request_id,
        )
        raise
    duration_ms = int((time.perf_counter() - start) * 1000)
    logger.info(
        "request_completed method=%s path=%s status=%s duration_ms=%s request_id=%s",
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
        request_id,
    )
    response.headers["x-request-id"] = request_id
    return response


@app.get("/health")
async def health():
    return {"status": "ok", "env": settings.env}


@app.post("/auth/google")
async def auth_google(payload: AuthRequest):
    try:
        return await login_with_google(payload.id_token)
    except AuthError as exc:
        raise HTTPException(status_code=401, detail=str(exc))


@app.post("/auth/apple")
async def auth_apple(payload: AuthRequest):
    try:
        return await login_with_apple(payload.id_token)
    except AuthError as exc:
        raise HTTPException(status_code=401, detail=str(exc))


@app.post("/ai/generate")
async def ai_generate(payload: GenerateRequest):
    provider_names = get_provider_order_for_task(payload.task)
    logger.info("ai_generate task=%s providers=%s", payload.task, ",".join(provider_names))
    router = build_provider_chain(provider_names)
    try:
        text = await router.generate(
            payload.prompt,
            {
                "temperature": payload.temperature,
                "max_tokens": payload.max_tokens,
                "task": payload.task,
            },
        )

        if payload.task == "generate_phrases":
            try:
                text = _validate_phrases_json(text)
            except Exception as exc:
                logger.warning("invalid_phrases_json error=%s", exc)
                repair_prompt = (
                    "Fix the following so it is ONLY a valid JSON array.\n"
                    "Each object must include EXACTLY these keys: "
                    "text, translation, category, difficulty.\n"
                    "No markdown, no code fences.\n\n"
                    f"INPUT:\n{text}"
                )
                text = await router.generate(
                    repair_prompt,
                    {
                        "temperature": 0.2,
                        "max_tokens": payload.max_tokens,
                        "task": payload.task,
                    },
                )
                text = _validate_phrases_json(text)
        logger.info(
            "ai_generate_response task=%s chars=%s preview=%s",
            payload.task,
            len(text),
            text[:500].replace("\n", "\\n"),
        )
        return {"text": text}
    except AIProviderError as exc:
        status = exc.status_code or 500
        raise HTTPException(status_code=status, detail=str(exc))
