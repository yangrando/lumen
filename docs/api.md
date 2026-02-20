# Lumen API Contract (Public)

This document describes the backend API contract consumed by the iOS app.

Base URL is environment-specific and injected via app configuration (`AI_BASE_URL` for AI endpoint).

## Authentication

### `POST /auth/google`
Validate a Google ID token and return an app access token.

Request:
```json
{
  "id_token": "google-id-token"
}
```

Success response (`200`):
```json
{
  "access_token": "jwt-token",
  "user": {
    "sub": "google-user-id",
    "email": "user@example.com"
  }
}
```

Error (`401`):
```json
{
  "detail": "Invalid Google ID token"
}
```

### `POST /auth/apple`
Validate an Apple ID token and return an app access token.

Request:
```json
{
  "id_token": "apple-id-token"
}
```

Success response (`200`):
```json
{
  "access_token": "jwt-token",
  "user": {
    "sub": "apple-user-id",
    "email": "user@example.com"
  }
}
```

Error (`401`):
```json
{
  "detail": "Invalid Apple ID token"
}
```

## AI

### `POST /ai/generate`
Generate text content for the app. Provider routing is internal to backend.

Request:
```json
{
  "prompt": "string",
  "temperature": 0.7,
  "max_tokens": 800,
  "task": "generate_phrases"
}
```

Request fields:
- `prompt` (required, string)
- `temperature` (optional, float, default `0.7`, range `0.0` to `2.0`)
- `max_tokens` (optional, integer, default `800`, range `1` to `4000`)
- `task` (optional, string): supported values:
  - `generate_phrases`
  - `explain_phrase`
  - `answer_doubt`
  - `translate_phrase`

Success response (`200`):
```json
{
  "text": "model output"
}
```

Error (`4xx`/`5xx`):
```json
{
  "detail": "error message"
}
```

## Health

### `GET /health`

Success response (`200`):
```json
{
  "status": "ok",
  "env": "local"
}
```

## Notes
- AI provider credentials must never be exposed in client apps.
- Backend owns provider selection, retries, rate limiting, and safety controls.
