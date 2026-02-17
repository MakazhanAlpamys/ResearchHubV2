"""Authentication dependencies for FastAPI."""

from __future__ import annotations

import logging

import jwt
from jwt import PyJWKClient
from fastapi import Depends, HTTPException, Request

from app.config import Settings, get_settings

logger = logging.getLogger(__name__)

_jwks_client: PyJWKClient | None = None


def _get_jwks_client(supabase_url: str) -> PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        jwks_url = f"{supabase_url}/auth/v1/.well-known/jwks.json"
        _jwks_client = PyJWKClient(jwks_url, cache_keys=True)
    return _jwks_client


async def require_auth(
    request: Request,
    settings: Settings = Depends(get_settings),
) -> str:
    """Verify Supabase JWT and return the user ID."""

    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization token")

    token = auth_header[len("Bearer "):]

    try:
        header = jwt.get_unverified_header(token)
        alg = header.get("alg", "HS256")

        if alg.startswith("HS"):
            # Symmetric — use JWT secret
            if not settings.supabase_jwt_secret:
                raise HTTPException(status_code=500, detail="Authentication is not configured on the server")
            payload = jwt.decode(
                token,
                settings.supabase_jwt_secret,
                algorithms=["HS256", "HS384", "HS512"],
                audience="authenticated",
            )
        else:
            # Asymmetric (ES256, RS256, etc.) — use JWKS public key
            client = _get_jwks_client(settings.supabase_url)
            signing_key = client.get_signing_key_from_jwt(token)
            payload = jwt.decode(
                token,
                signing_key.key,
                algorithms=[alg],
                audience="authenticated",
            )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError as e:
        logger.warning("JWT validation failed: %s", e)
        raise HTTPException(status_code=401, detail="Invalid token")

    user_id: str | None = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    return user_id
