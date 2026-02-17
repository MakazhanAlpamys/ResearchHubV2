"""Aggregate scientific papers from arXiv, OpenAlex, and Semantic Scholar."""

from __future__ import annotations

import asyncio
import logging
import xml.etree.ElementTree as ET

import httpx

from app.models.paper import Paper, PaperSearchResult, SourceStatus

logger = logging.getLogger(__name__)

_ARXIV_API = "https://export.arxiv.org/api/query"
_OPENALEX_API = "https://api.openalex.org/works"
_SEM_SCHOLAR_API = "https://api.semanticscholar.org/graph/v1/paper/search"

_TIMEOUT = httpx.Timeout(20.0)


# ── arXiv ────────────────────────────────────────────────────

async def _search_arxiv(
    query: str,
    max_results: int = 10,
    start: int = 0,
    year_from: int | None = None,
    year_to: int | None = None,
) -> list[Paper]:
    # arXiv doesn't support server-side year filtering, so fetch extra
    # results when a year range is active and trim after filtering.
    year_filter_active = bool(year_from or year_to)
    fetch_count = max_results * 3 if year_filter_active else max_results
    fetch_start = start * 3 if year_filter_active else start

    params = {
        "search_query": f"all:{query}",
        "start": fetch_start,
        "max_results": fetch_count,
        "sortBy": "relevance",
        "sortOrder": "descending",
    }
    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        resp = await client.get(_ARXIV_API, params=params)
        resp.raise_for_status()

    ns = {"atom": "http://www.w3.org/2005/Atom"}
    root = ET.fromstring(resp.text)
    papers: list[Paper] = []

    for entry in root.findall("atom:entry", ns):
        published_raw = (entry.findtext("atom:published", "", ns) or "")[:10]
        if year_from or year_to:
            try:
                pub_year = int(published_raw[:4])
            except (ValueError, IndexError):
                pub_year = 0
            if year_from and pub_year < year_from:
                continue
            if year_to and pub_year > year_to:
                continue

        arxiv_id = (entry.findtext("atom:id", "", ns) or "").split("/abs/")[-1]
        title = (entry.findtext("atom:title", "", ns) or "").strip().replace("\n", " ")
        abstract = (entry.findtext("atom:summary", "", ns) or "").strip().replace("\n", " ")
        authors = [
            a.findtext("atom:name", "", ns)
            for a in entry.findall("atom:author", ns)
        ]

        pdf_url = ""
        for link in entry.findall("atom:link", ns):
            if link.get("title") == "pdf":
                pdf_url = link.get("href", "")
                break

        papers.append(Paper(
            paper_id=f"arxiv:{arxiv_id}",
            title=title,
            authors=authors,
            abstract=abstract,
            published_date=published_raw or None,
            source="arxiv",
            url=f"https://arxiv.org/abs/{arxiv_id}",
            pdf_url=pdf_url,
        ))

    return papers[:max_results]


# ── OpenAlex ─────────────────────────────────────────────────

async def _search_openalex(
    query: str,
    max_results: int = 10,
    page: int = 1,
    year_from: int | None = None,
    year_to: int | None = None,
) -> list[Paper]:
    filters: list[str] = []
    if year_from:
        filters.append(f"from_publication_date:{year_from}-01-01")
    if year_to:
        filters.append(f"to_publication_date:{year_to}-12-31")

    params: dict[str, str | int] = {
        "search": query,
        "per_page": max_results,
        "page": page,
        "select": "id,title,authorships,publication_date,open_access,abstract_inverted_index",
    }
    if filters:
        params["filter"] = ",".join(filters)

    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        resp = await client.get(
            _OPENALEX_API,
            params=params,
            headers={"User-Agent": "ResearchHubV2/1.0 (mailto:dev@researchhub.local)"},
        )
        resp.raise_for_status()

    data = resp.json()
    papers: list[Paper] = []

    for work in data.get("results", []):
        openalex_id = work.get("id", "").split("/")[-1]
        title = work.get("title") or ""
        authors = [
            a.get("author", {}).get("display_name", "")
            for a in work.get("authorships", [])
        ]

        # Reconstruct abstract from inverted index
        abstract = _reconstruct_abstract(work.get("abstract_inverted_index"))

        oa = work.get("open_access", {}) or {}
        pdf_url = oa.get("oa_url") or ""

        papers.append(Paper(
            paper_id=f"openalex:{openalex_id}",
            title=title,
            authors=authors,
            abstract=abstract,
            published_date=work.get("publication_date"),
            source="openalex",
            url=work.get("id", ""),
            pdf_url=pdf_url,
        ))

    return papers


def _reconstruct_abstract(inverted_index: dict | None) -> str:
    if not inverted_index:
        return ""
    word_positions: list[tuple[int, str]] = []
    for word, positions in inverted_index.items():
        for pos in positions:
            word_positions.append((pos, word))
    word_positions.sort()
    return " ".join(w for _, w in word_positions)


# ── Semantic Scholar ─────────────────────────────────────────

async def _search_semantic_scholar(
    query: str,
    max_results: int = 10,
    offset: int = 0,
    year_from: int | None = None,
    year_to: int | None = None,
) -> list[Paper]:
    params: dict[str, str | int] = {
        "query": query,
        "limit": max_results,
        "offset": offset,
        "fields": "paperId,title,authors,abstract,year,externalIds,url,openAccessPdf",
    }
    if year_from and year_to:
        params["year"] = f"{year_from}-{year_to}"
    elif year_from:
        params["year"] = f"{year_from}-"
    elif year_to:
        params["year"] = f"-{year_to}"

    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        resp = await client.get(_SEM_SCHOLAR_API, params=params)
        if resp.status_code == 429:
            return []  # rate-limited – graceful fallback
        resp.raise_for_status()

    data = resp.json()
    papers: list[Paper] = []

    for item in data.get("data", []):
        paper_id = item.get("paperId", "")
        title = item.get("title") or ""
        authors = [a.get("name", "") for a in (item.get("authors") or [])]
        abstract = item.get("abstract") or ""
        year = item.get("year")
        pub_date = f"{year}-01-01" if year else None

        oa = item.get("openAccessPdf") or {}
        pdf_url = oa.get("url", "")

        papers.append(Paper(
            paper_id=f"s2:{paper_id}",
            title=title,
            authors=authors,
            abstract=abstract,
            published_date=pub_date,
            source="semantic_scholar",
            url=item.get("url") or f"https://www.semanticscholar.org/paper/{paper_id}",
            pdf_url=pdf_url,
        ))

    return papers


# ── Public API ───────────────────────────────────────────────

async def search_papers(
    query: str,
    page: int = 1,
    per_page: int = 10,
    source: str | None = None,
    year_from: int | None = None,
    year_to: int | None = None,
) -> PaperSearchResult:
    """Search across multiple academic sources concurrently."""
    offset = (page - 1) * per_page
    tasks: list = []

    sources = [source] if source else ["arxiv", "openalex", "semantic_scholar"]

    source_names: list[str] = []
    if "arxiv" in sources:
        source_names.append("arxiv")
        tasks.append(_search_arxiv(query, per_page, offset, year_from, year_to))
    if "openalex" in sources:
        source_names.append("openalex")
        tasks.append(_search_openalex(query, per_page, page, year_from, year_to))
    if "semantic_scholar" in sources:
        source_names.append("semantic_scholar")
        tasks.append(_search_semantic_scholar(query, per_page, offset, year_from, year_to))

    results = await asyncio.gather(*tasks, return_exceptions=True)

    all_papers: list[Paper] = []
    source_statuses: list[SourceStatus] = []
    for name, r in zip(source_names, results):
        if isinstance(r, list):
            all_papers.extend(r)
            source_statuses.append(SourceStatus(name=name, ok=True))
        elif isinstance(r, Exception):
            logger.warning("Source %s failed: %s", name, r)
            source_statuses.append(
                SourceStatus(name=name, ok=False, error=str(type(r).__name__))
            )

    # Deduplicate by title (case-insensitive)
    seen: set[str] = set()
    unique: list[Paper] = []
    for p in all_papers:
        key = p.title.lower().strip()
        if key not in seen:
            seen.add(key)
            unique.append(p)

    page_papers = unique[:per_page]
    # has_more is True only when we got enough results to fill a page
    # from at least one source (indicating more data likely exists).
    has_more = len(unique) > per_page or (
        len(page_papers) == per_page
        and any(isinstance(r, list) and len(r) == per_page for r in results)
    )

    return PaperSearchResult(
        total=len(unique),
        page=page,
        per_page=per_page,
        has_more=has_more,
        papers=page_papers,
        sources=source_statuses,
    )
