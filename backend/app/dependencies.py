"""Authentication dependencies for FastAPI."""

from __future__ import annotations

import logging

import jwt
from fastapi import Depends, HTTPException, Request

from app.config import Settings, get_settings

logger = logging.getLogger(__name__)


async def require_auth(
    request: Request,
    settings: Settings = Depends(get_settings),
) -> str:
    """Verify Supabase JWT and return the user ID.

    Raises HTTPException 401 if token is missing or invalid.
    """
    if not settings.supabase_jwt_secret:
        raise HTTPException(
            status_code=500,
            detail="Authentication is not configured on the server",
        )

    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization token")

    token = auth_header[len("Bearer "):]

    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user_id: str | None = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    return user_id
