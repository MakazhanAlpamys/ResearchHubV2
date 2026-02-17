from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException

from app.dependencies import require_auth
from app.models.paper import (
    AnalyzePdfRequest,
    AnalyzePdfResponse,
    SummarizeRequest,
    SummarizeResponse,
)
from app.services.gemini_service import analyze_pdf, summarize_paper

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai", tags=["AI"])


@router.post("/summarize", response_model=SummarizeResponse)
async def summarize(
    body: SummarizeRequest,
    user_id: str = Depends(require_auth),
) -> SummarizeResponse:
    if body.language not in ("en", "ru", "kk"):
        raise HTTPException(status_code=400, detail="Unsupported language")

    try:
        summary = await summarize_paper(
            title=body.title,
            abstract=body.abstract,
            language=body.language,
        )
    except Exception as exc:
        logger.exception("AI summarization failed for user %s", user_id)
        raise HTTPException(status_code=502, detail="AI service is temporarily unavailable")

    return SummarizeResponse(summary=summary, language=body.language)


@router.post("/analyze-pdf", response_model=AnalyzePdfResponse)
async def analyze_pdf_endpoint(
    body: AnalyzePdfRequest,
    user_id: str = Depends(require_auth),
) -> AnalyzePdfResponse:
    if body.language not in ("en", "ru", "kk"):
        raise HTTPException(status_code=400, detail="Unsupported language")

    try:
        analysis = await analyze_pdf(
            pdf_url=body.pdf_url,
            language=body.language,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.exception("PDF analysis failed for user %s", user_id)
        raise HTTPException(status_code=502, detail="AI service is temporarily unavailable")

    return AnalyzePdfResponse(analysis=analysis, language=body.language)
