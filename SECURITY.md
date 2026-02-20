# Security Guidelines

This repository is public for code transparency. It is not intended to contain deploy-ready production secrets or infrastructure.

## What must never be committed
- API keys and tokens (`OPENAI_API_KEY`, `GEMINI_API_KEY`, OAuth client secrets, etc.)
- Private keys, certificates, keystores, provisioning secrets
- Real user data, exports, backups, and database dumps
- Production `.env` files and cloud credentials

## Architecture boundary
- iOS app is public code.
- Backend runtime secrets and production infrastructure are private.
- All AI provider keys must stay server-side only.
- Client apps must call backend APIs, never third-party AI APIs directly.

## Required controls
- Use separate credentials for `local`, `staging`, and `production`.
- Rotate keys immediately if exposed.
- Enforce rate limits and abuse protection on backend endpoints.
- Keep audit logs for authentication and AI calls.

## Local development
- Copy `backend/.env.example` to `backend/.env`.
- Never commit `backend/.env`.
- Use test credentials only.

## Incident response
If a secret is exposed:
1. Revoke and rotate the secret immediately.
2. Remove any committed secret from current files.
3. Verify no dependent systems are still using the compromised secret.
4. Review logs for suspicious usage.
