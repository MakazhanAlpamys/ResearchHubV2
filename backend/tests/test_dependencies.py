"""Tests for the require_auth dependency (JWT validation)."""

import time
from unittest.mock import MagicMock

import jwt as pyjwt
import pytest
from fastapi import HTTPException

from app.config import Settings
from app.dependencies import require_auth
from tests.conftest import _TEST_JWT_SECRET, make_token


def _make_settings() -> Settings:
    return Settings(
        gemini_api_key="fake",
        supabase_url="https://test.supabase.co",
        supabase_anon_key="fake",
        supabase_jwt_secret=_TEST_JWT_SECRET,
        allowed_origins="http://localhost:3000",
    )


async def _call_require_auth(token_str: str | None, settings: Settings | None = None) -> str:
    if settings is None:
        settings = _make_settings()
    request = MagicMock()
    if token_str:
        request.headers.get.return_value = f"Bearer {token_str}"
    else:
        request.headers.get.return_value = ""
    return await require_auth(request=request, settings=settings)


async def test_valid_token_returns_user_id():
    token = make_token(user_id="user-abc-123")
    user_id = await _call_require_auth(token)
    assert user_id == "user-abc-123"


async def test_missing_token_raises_401():
    with pytest.raises(HTTPException) as exc_info:
        await _call_require_auth(None)
    assert exc_info.value.status_code == 401


async def test_expired_token_raises_401():
    token = make_token(expired=True)
    with pytest.raises(HTTPException) as exc_info:
        await _call_require_auth(token)
    assert exc_info.value.status_code == 401


async def test_invalid_token_raises_401():
    with pytest.raises(HTTPException) as exc_info:
        await _call_require_auth("not-a-real-jwt")
    assert exc_info.value.status_code == 401


async def test_token_without_sub_raises_401():
    payload = {
        "aud": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
    }
    token = pyjwt.encode(payload, _TEST_JWT_SECRET, algorithm="HS256")
    with pytest.raises(HTTPException) as exc_info:
        await _call_require_auth(token)
    assert exc_info.value.status_code == 401


async def test_wrong_secret_raises_401():
    payload = {
        "sub": "user-123",
        "aud": "authenticated",
        "iat": int(time.time()),
        "exp": int(time.time()) + 3600,
    }
    token = pyjwt.encode(payload, "wrong-secret", algorithm="HS256")
    with pytest.raises(HTTPException) as exc_info:
        await _call_require_auth(token)
    assert exc_info.value.status_code == 401
