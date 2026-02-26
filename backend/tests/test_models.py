"""Tests for Pydantic models in app.models.paper."""

from app.models.paper import (
    AnalyzePdfRequest,
    AnalyzePdfResponse,
    Paper,
    PaperSearchResult,
    SourceStatus,
    SummarizeRequest,
    SummarizeResponse,
)


class TestPaper:
    def test_create_with_all_fields(self):
        p = Paper(
            paper_id="arxiv:2301.00001",
            title="Test Paper",
            authors=["Alice", "Bob"],
            abstract="An abstract.",
            published_date="2023-01-01",
            source="arxiv",
            url="https://arxiv.org/abs/2301.00001",
            pdf_url="https://arxiv.org/pdf/2301.00001",
        )
        assert p.paper_id == "arxiv:2301.00001"
        assert p.authors == ["Alice", "Bob"]
        assert p.pdf_url == "https://arxiv.org/pdf/2301.00001"

    def test_create_with_defaults(self):
        p = Paper(paper_id="s2:abc", title="Minimal")
        assert p.authors == []
        assert p.abstract == ""
        assert p.published_date is None
        assert p.source == ""
        assert p.url == ""
        assert p.pdf_url == ""

    def test_serialization_roundtrip(self):
        p = Paper(paper_id="openalex:W123", title="Test", authors=["A"])
        data = p.model_dump()
        p2 = Paper(**data)
        assert p == p2


class TestSourceStatus:
    def test_ok_status(self):
        s = SourceStatus(name="arxiv", ok=True)
        assert s.error is None

    def test_error_status(self):
        s = SourceStatus(name="openalex", ok=False, error="HTTPStatusError")
        assert not s.ok
        assert s.error == "HTTPStatusError"


class TestPaperSearchResult:
    def test_full_result(self):
        r = PaperSearchResult(
            total=42,
            page=2,
            per_page=10,
            has_more=True,
            papers=[Paper(paper_id="x", title="X")],
            sources=[SourceStatus(name="arxiv", ok=True)],
        )
        assert r.total == 42
        assert len(r.papers) == 1
        assert len(r.sources) == 1

    def test_empty_result(self):
        r = PaperSearchResult(total=0, page=1, per_page=10, papers=[])
        assert r.papers == []
        assert r.sources == []
        assert r.has_more is True  # default


class TestSummarizeModels:
    def test_request_default_language(self):
        req = SummarizeRequest(title="T", abstract="A")
        assert req.language == "en"

    def test_request_custom_language(self):
        req = SummarizeRequest(title="T", abstract="A", language="ru")
        assert req.language == "ru"

    def test_response_fields(self):
        resp = SummarizeResponse(summary="A summary", language="en")
        assert resp.summary == "A summary"


class TestAnalyzePdfModels:
    def test_request_default_language(self):
        req = AnalyzePdfRequest(pdf_url="https://example.com/paper.pdf")
        assert req.language == "en"

    def test_response_fields(self):
        resp = AnalyzePdfResponse(analysis="Analysis text", language="kk")
        assert resp.analysis == "Analysis text"
        assert resp.language == "kk"
