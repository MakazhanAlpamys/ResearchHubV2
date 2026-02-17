from __future__ import annotations

from fastapi import APIRouter, Query

from app.models.paper import PaperSearchResult
from app.services.paper_aggregator import search_papers

router = APIRouter(prefix="/papers", tags=["Papers"])


@router.get("/search", response_model=PaperSearchResult)
async def search(
    query: str = Query(..., min_length=1, max_length=300),
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=50),
    source: str | None = Query(None, pattern=r"^(arxiv|openalex|semantic_scholar)$"),
    year_from: int | None = Query(None, ge=1900, le=2100),
    year_to: int | None = Query(None, ge=1900, le=2100),
) -> PaperSearchResult:
    return await search_papers(
        query=query,
        page=page,
        per_page=per_page,
        source=source,
        year_from=year_from,
        year_to=year_to,
    )
