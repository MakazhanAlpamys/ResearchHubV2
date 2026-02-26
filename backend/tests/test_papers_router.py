"""Tests for GET /api/papers/search."""

from unittest.mock import AsyncMock, patch

import pytest

from app.models.paper import Paper


def _fake_papers(source: str, count: int = 2) -> list[Paper]:
    return [
        Paper(
            paper_id=f"{source}:{i}",
            title=f"Paper {i} from {source}",
            authors=[f"Author {i}"],
            abstract=f"Abstract {i}",
            source=source,
        )
        for i in range(count)
    ]


@pytest.fixture()
def mock_search_sources():
    """Patch all three search backends to return fake data."""
    with (
        patch(
            "app.services.paper_aggregator._search_arxiv",
            new_callable=AsyncMock,
            return_value=_fake_papers("arxiv"),
        ) as m_arxiv,
        patch(
            "app.services.paper_aggregator._search_openalex",
            new_callable=AsyncMock,
            return_value=_fake_papers("openalex"),
        ) as m_openalex,
        patch(
            "app.services.paper_aggregator._search_semantic_scholar",
            new_callable=AsyncMock,
            return_value=_fake_papers("semantic_scholar"),
        ) as m_s2,
    ):
        yield {"arxiv": m_arxiv, "openalex": m_openalex, "semantic_scholar": m_s2}


async def test_search_returns_papers(client, mock_search_sources):
    resp = await client.get("/api/papers/search", params={"query": "quantum"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] > 0
    assert len(data["papers"]) > 0
    assert len(data["sources"]) == 3
    assert all(s["ok"] for s in data["sources"])


async def test_search_requires_query(client):
    resp = await client.get("/api/papers/search")
    assert resp.status_code == 422


async def test_search_with_source_filter(client, mock_search_sources):
    resp = await client.get(
        "/api/papers/search",
        params={"query": "quantum", "source": "arxiv"},
    )
    assert resp.status_code == 200


async def test_search_handles_partial_source_failure(client):
    """When one source fails, others still return results."""
    with (
        patch(
            "app.services.paper_aggregator._search_arxiv",
            new_callable=AsyncMock,
            return_value=_fake_papers("arxiv"),
        ),
        patch(
            "app.services.paper_aggregator._search_openalex",
            new_callable=AsyncMock,
            side_effect=Exception("OpenAlex is down"),
        ),
        patch(
            "app.services.paper_aggregator._search_semantic_scholar",
            new_callable=AsyncMock,
            return_value=_fake_papers("semantic_scholar"),
        ),
    ):
        resp = await client.get("/api/papers/search", params={"query": "test"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] > 0
        openalex_status = next(s for s in data["sources"] if s["name"] == "openalex")
        assert openalex_status["ok"] is False


async def test_search_deduplicates_by_title(client):
    """Papers with the same title from different sources are deduplicated."""
    dup1 = Paper(paper_id="arxiv:dup1", title="Duplicate Paper", source="arxiv")
    dup2 = Paper(paper_id="s2:dup2", title="Duplicate Paper", source="semantic_scholar")
    with (
        patch(
            "app.services.paper_aggregator._search_arxiv",
            new_callable=AsyncMock,
            return_value=[dup1],
        ),
        patch(
            "app.services.paper_aggregator._search_openalex",
            new_callable=AsyncMock,
            return_value=[],
        ),
        patch(
            "app.services.paper_aggregator._search_semantic_scholar",
            new_callable=AsyncMock,
            return_value=[dup2],
        ),
    ):
        resp = await client.get("/api/papers/search", params={"query": "dup"})
        data = resp.json()
        assert data["total"] == 1
