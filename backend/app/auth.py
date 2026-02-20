import time
from typing import Any, Dict

import httpx
import jwt
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

from .config import settings

APPLE_ISSUER = "https://appleid.apple.com"
APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
GOOGLE_ISSUER = "https://accounts.google.com"


class AuthError(Exception):
    pass


def _issue_app_token(sub: str, provider: str, email: str | None) -> str:
    now = int(time.time())
    payload = {
        "iss": settings.jwt_issuer,
        "aud": settings.jwt_audience,
        "iat": now,
        "exp": now + 60 * 60 * 24 * 7,  # 7 days
        "sub": sub,
        "provider": provider,
        "email": email,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


async def verify_google_id_token(id_token: str) -> Dict[str, Any]:
    if not settings.google_client_id:
        raise AuthError("GOOGLE_CLIENT_ID not configured")

    try:
        idinfo = google_id_token.verify_oauth2_token(
            id_token,
            google_requests.Request(),
            settings.google_client_id,
            clock_skew_in_seconds=10,
        )
    except Exception as exc:
        raise AuthError(f"Invalid Google ID token: {exc}") from exc

    if idinfo.get("iss") not in {GOOGLE_ISSUER, "accounts.google.com"}:
        raise AuthError("Invalid Google token issuer")

    return idinfo


async def verify_apple_id_token(id_token: str) -> Dict[str, Any]:
    if not settings.apple_client_id:
        raise AuthError("APPLE_CLIENT_ID not configured")

    async with httpx.AsyncClient(timeout=10) as client:
        jwks_resp = await client.get(APPLE_JWKS_URL)
        jwks_resp.raise_for_status()
        jwks = jwks_resp.json()

    unverified_header = jwt.get_unverified_header(id_token)
    kid = unverified_header.get("kid")
    if not kid:
        raise AuthError("Missing kid in Apple token header")

    key = None
    for jwk in jwks.get("keys", []):
        if jwk.get("kid") == kid:
            key = jwk
            break

    if not key:
        raise AuthError("Apple public key not found")

    try:
        payload = jwt.decode(
            id_token,
            key,
            algorithms=["RS256"],
            audience=settings.apple_client_id,
            issuer=APPLE_ISSUER,
            options={"verify_at_hash": False},
        )
    except Exception as exc:
        raise AuthError(f"Invalid Apple ID token: {exc}") from exc

    return payload


async def login_with_google(id_token: str) -> Dict[str, Any]:
    payload = await verify_google_id_token(id_token)
    token = _issue_app_token(
        sub=payload.get("sub"),
        provider="google",
        email=payload.get("email"),
    )
    return {"access_token": token, "user": payload}


async def login_with_apple(id_token: str) -> Dict[str, Any]:
    payload = await verify_apple_id_token(id_token)
    token = _issue_app_token(
        sub=payload.get("sub"),
        provider="apple",
        email=payload.get("email"),
    )
    return {"access_token": token, "user": payload}
