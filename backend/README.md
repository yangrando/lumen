# Lumen Backend (Local)

Backend em Python para autenticação (Apple/Google) e gateway de IA com fallback.

## Setup

```bash
cd /Users/yanfelipegrando/Documents/GitHub/Lumen/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

## Security notes
- Do not commit `.env` files or API keys.
- Keep provider keys only on backend.
- Rotate any key that was ever exposed in logs/chat/history.

## Rodar local

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints
- `GET /health`
- `POST /auth/google` (body: `{ "id_token": "..." }`)
- `POST /auth/apple` (body: `{ "id_token": "..." }`)
- `POST /ai/generate` (body: `{ "prompt": "...", "temperature": 0.7, "max_tokens": 800, "task": "generate_phrases" }`)

## Provider routing
Use these tasks to route between providers:
- `generate_phrases` (default: Gemini, fallback OpenAI)
- `explain_phrase` / `answer_doubt` (default: OpenAI, fallback Gemini)
- `translate_phrase` (default: OpenAI, fallback Gemini)
