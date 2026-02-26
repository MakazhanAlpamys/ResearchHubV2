"""Tests for POST /api/ai/summarize and POST /api/ai/analyze-pdf."""

from unittest.mock import AsyncMock, patch

import pytest


# ── Auth tests ───────────────────────────────────────────────


async def test_summarize_requires_auth(client):
    resp = await client.post("/api/ai/summarize", json={"title": "T", "abstract": "A"})
    assert resp.status_code == 401


async def test_analyze_pdf_requires_auth(client):
    resp = await client.post(
        "/api/ai/analyze-pdf", json={"pdf_url": "https://example.com/paper.pdf"}
    )
    assert resp.status_code == 401


async def test_summarize_rejects_expired_token(client, expired_auth_header):
    resp = await client.post(
        "/api/ai/summarize",
        json={"title": "T", "abstract": "A"},
        headers=expired_auth_header,
    )
    assert resp.status_code == 401


async def test_summarize_rejects_invalid_token(client):
    resp = await client.post(
        "/api/ai/summarize",
        json={"title": "T", "abstract": "A"},
        headers={"Authorization": "Bearer not-a-real-jwt"},
    )
    assert resp.status_code == 401


# ── Summarize ────────────────────────────────────────────────


@patch(
    "app.routers.ai.summarize_paper",
    new_callable=AsyncMock,
    return_value="This is a test summary.",
)
async def test_summarize_success(mock_summarize, client, auth_header):
    resp = await client.post(
        "/api/ai/summarize",
        json={"title": "Quantum Computing", "abstract": "We study...", "language": "en"},
        headers=auth_header,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["summary"] == "This is a test summary."
    assert data["language"] == "en"


@patch(
    "app.routers.ai.summarize_paper",
    new_callable=AsyncMock,
    return_value="Резюме на русском.",
)
async def test_summarize_russian(mock_summarize, client, auth_header):
    resp = await client.post(
        "/api/ai/summarize",
        json={"title": "T", "abstract": "A", "language": "ru"},
        headers=auth_header,
    )
    assert resp.status_code == 200
    assert resp.json()["language"] == "ru"


async def test_summarize_rejects_unsupported_language(client, auth_header):
    resp = await client.post(
        "/api/ai/summarize",
        json={"title": "T", "abstract": "A", "language": "fr"},
        headers=auth_header,
    )
    assert resp.status_code == 400


@patch(
    "app.routers.ai.summarize_paper",
    new_callable=AsyncMock,
    side_effect=Exception("Gemini is down"),
)
async def test_summarize_handles_gemini_failure(mock_summarize, client, auth_header):
    resp = await client.post(
        "/api/ai/summarize",
        json={"title": "T", "abstract": "A"},
        headers=auth_header,
    )
    assert resp.status_code == 502


# ── Analyze PDF ──────────────────────────────────────────────


@patch(
    "app.routers.ai.analyze_pdf",
    new_callable=AsyncMock,
    return_value="Detailed PDF analysis.",
)
async def test_analyze_pdf_success(mock_analyze, client, auth_header):
    resp = await client.post(
        "/api/ai/analyze-pdf",
        json={"pdf_url": "https://arxiv.org/pdf/2301.00001", "language": "en"},
        headers=auth_header,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["analysis"] == "Detailed PDF analysis."
    assert data["language"] == "en"


async def test_analyze_pdf_rejects_unsupported_language(client, auth_header):
    resp = await client.post(
        "/api/ai/analyze-pdf",
        json={"pdf_url": "https://example.com/paper.pdf", "language": "de"},
        headers=auth_header,
    )
    assert resp.status_code == 400


@patch(
    "app.routers.ai.analyze_pdf",
    new_callable=AsyncMock,
    side_effect=ValueError("URL does not point to a PDF file"),
)
async def test_analyze_pdf_handles_value_error(mock_analyze, client, auth_header):
    resp = await client.post(
        "/api/ai/analyze-pdf",
        json={"pdf_url": "https://example.com/not-a-pdf"},
        headers=auth_header,
    )
    assert resp.status_code == 400


@patch(
    "app.routers.ai.analyze_pdf",
    new_callable=AsyncMock,
    side_effect=Exception("Gemini down"),
)
async def test_analyze_pdf_handles_gemini_failure(mock_analyze, client, auth_header):
    resp = await client.post(
        "/api/ai/analyze-pdf",
        json={"pdf_url": "https://arxiv.org/pdf/2301.00001"},
        headers=auth_header,
    )
    assert resp.status_code == 502
