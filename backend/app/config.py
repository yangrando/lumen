import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings
from pydantic import Field

load_dotenv()


class Settings(BaseSettings):
    env: str = Field(default="local", validation_alias="ENV")

    # Auth
    jwt_secret: str = Field(default="dev-secret-change-me", validation_alias="JWT_SECRET")
    jwt_issuer: str = Field(default="lumen-backend", validation_alias="JWT_ISSUER")
    jwt_audience: str = Field(default="lumen-app", validation_alias="JWT_AUDIENCE")

    google_client_id: str | None = Field(default=None, validation_alias="GOOGLE_CLIENT_ID")
    apple_client_id: str | None = Field(default=None, validation_alias="APPLE_CLIENT_ID")

    # OpenAI
    openai_api_key: str | None = Field(default=None, validation_alias="OPENAI_API_KEY")
    openai_base_url: str = Field(default="https://api.openai.com/v1/responses", validation_alias="OPENAI_BASE_URL")
    openai_model: str = Field(default="gpt-4.1-mini", validation_alias="OPENAI_MODEL")

    # Gemini
    gemini_api_key: str | None = Field(default=None, validation_alias="GEMINI_API_KEY")
    gemini_base_url: str = Field(
        default="https://generativelanguage.googleapis.com/v1beta",
        validation_alias="GEMINI_BASE_URL",
    )
    gemini_model: str = Field(default="gemini-2.5-flash", validation_alias="GEMINI_MODEL")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


settings = Settings()


def get_provider_order() -> list[str]:
    raw = os.getenv("AI_PROVIDER_ORDER", "openai")
    if not raw or not raw.strip():
        raw = "openai"
    return [v.strip() for v in raw.split(",") if v.strip()]


def get_provider_order_for_task(task: str | None) -> list[str]:
    if not task:
        return get_provider_order()

    task_key = task.strip().lower()
    if task_key == "generate_phrases":
        raw = os.getenv("AI_PROVIDER_ORDER_PHRASES", "")
    elif task_key in {"explain_phrase", "answer_doubt"}:
        raw = os.getenv("AI_PROVIDER_ORDER_EXPLAIN", "")
    elif task_key == "translate_phrase":
        raw = os.getenv("AI_PROVIDER_ORDER_TRANSLATE", "")
    else:
        raw = ""

    if not raw or not raw.strip():
        return get_provider_order()

    return [v.strip() for v in raw.split(",") if v.strip()]
