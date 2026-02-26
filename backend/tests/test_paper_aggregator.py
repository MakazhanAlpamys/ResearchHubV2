"""Tests for paper_aggregator service."""

from unittest.mock import AsyncMock, patch

import httpx
import pytest

from app.models.paper import Paper
from app.services.paper_aggregator import _reconstruct_abstract, search_papers


class TestReconstructAbstract:
    def test_none_returns_empty(self):
        assert _reconstruct_abstract(None) == ""

    def test_empty_dict_returns_empty(self):
        assert _reconstruct_abstract({}) == ""

    def test_basic_reconstruction(self):
        inverted = {"Hello": [0], "world": [1], "of": [2], "science": [3]}
        assert _reconstruct_abstract(inverted) == "Hello world of science"

    def test_handles_multiple_positions(self):
        inverted = {"the": [0, 3], "cat": [1], "sat": [2], "mat": [4]}
        assert _reconstruct_abstract(inverted) == "the cat sat the mat"


class TestSearchPapers:
    @pytest.fixture()
    def mock_all_sources(self):
        with (
            patch(
                "app.services.paper_aggregator._search_arxiv",
                new_callable=AsyncMock,
                return_value=[
                    Paper(paper_id="arxiv:1", title="ArXiv Paper", source="arxiv"),
                ],
            ),
            patch(
                "app.services.paper_aggregator._search_openalex",
                new_callable=AsyncMock,
                return_value=[
                    Paper(paper_id="oa:1", title="OpenAlex Paper", source="openalex"),
                ],
            ),
            patch(
                "app.services.paper_aggregator._search_semantic_scholar",
                new_callable=AsyncMock,
                return_value=[
                    Paper(paper_id="s2:1", title="S2 Paper", source="semantic_scholar"),
                ],
            ),
        ):
            yield

    async def test_aggregates_all_sources(self, mock_all_sources):
        result = await search_papers(query="test")
        assert result.total == 3
        assert len(result.sources) == 3
        assert all(s.ok for s in result.sources)

    async def test_single_source_filter(self, mock_all_sources):
        result = await search_papers(query="test", source="arxiv")
        assert len(result.sources) == 1
        assert result.sources[0].name == "arxiv"

    async def test_deduplication(self):
        dup1 = Paper(paper_id="arxiv:1", title="Same Title", source="arxiv")
        dup2 = Paper(paper_id="s2:2", title="same title", source="semantic_scholar")
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
            result = await search_papers(query="dup")
            assert result.total == 1

    async def test_graceful_source_failure(self):
        with (
            patch(
                "app.services.paper_aggregator._search_arxiv",
                new_callable=AsyncMock,
                return_value=[Paper(paper_id="arxiv:1", title="Good", source="arxiv")],
            ),
            patch(
                "app.services.paper_aggregator._search_openalex",
                new_callable=AsyncMock,
                side_effect=httpx.ConnectError("Connection refused"),
            ),
            patch(
                "app.services.paper_aggregator._search_semantic_scholar",
                new_callable=AsyncMock,
                return_value=[],
            ),
        ):
            result = await search_papers(query="test")
            assert result.total == 1
            openalex = next(s for s in result.sources if s.name == "openalex")
            assert openalex.ok is False
            assert openalex.error is not None
