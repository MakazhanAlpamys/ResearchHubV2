"""Shared fixtures for backend tests."""

from __future__ import annotations

import time

import jwt as pyjwt
import pytest
from httpx import ASGITransport, AsyncClient

from app.config import Settings, get_settings
from main import app

_TEST_JWT_SECRET = "test-jwt-secret-for-unit-tests"


def _test_settings() -> Settings:
    return Settings(
        gemini_api_key="fake-gemini-key",
        supabase_url="https://test.supabase.co",
        supabase_anon_key="fake-anon-key",
        supabase_jwt_secret=_TEST_JWT_SECRET,
        allowed_origins="http://localhost:3000",
    )


@pytest.fixture()
def settings():
    return _test_settings()


@pytest.fixture(autouse=True)
def _override_settings():
    """Replace get_settings globally for every test."""
    app.dependency_overrides[get_settings] = _test_settings
    yield
    app.dependency_overrides.clear()


@pytest.fixture()
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


def make_token(
    user_id: str = "test-user-id-123",
    expired: bool = False,
) -> str:
    """Create a valid HS256 JWT matching what Supabase would issue."""
    now = int(time.time())
    payload = {
        "sub": user_id,
        "aud": "authenticated",
        "iat": now,
        "exp": (now - 3600) if expired else (now + 3600),
    }
    return pyjwt.encode(payload, _TEST_JWT_SECRET, algorithm="HS256")


@pytest.fixture()
def auth_header() -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token()}"}


@pytest.fixture()
def expired_auth_header() -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(expired=True)}"}
