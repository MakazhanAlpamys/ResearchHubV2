"""Google Gemini summarization service."""

from __future__ import annotations

import logging

import google.generativeai as genai
import httpx

from app.config import get_settings

logger = logging.getLogger(__name__)

_LANGUAGE_NAMES = {
    "en": "English",
    "ru": "Russian",
    "kk": "Kazakh",
}

_MODEL_NAME = "gemini-2.5-flash"
_configured = False
_PDF_TIMEOUT = httpx.Timeout(30.0)
_MAX_PDF_SIZE = 20 * 1024 * 1024  # 20 MB


def _configure() -> None:
    global _configured
    if _configured:
        return
    settings = get_settings()
    genai.configure(api_key=settings.gemini_api_key)
    _configured = True


async def summarize_paper(
    title: str,
    abstract: str,
    language: str = "en",
) -> str:
    """Return a concise summary of the paper in the requested language."""
    _configure()

    lang_name = _LANGUAGE_NAMES.get(language, "English")

    prompt = (
        f"You are an expert scientific research assistant.\n"
        f"Summarize the following academic paper in {lang_name}.\n"
        f"Provide a clear, concise summary (3-5 paragraphs) covering:\n"
        f"1. The main objective / research question\n"
        f"2. The methodology used\n"
        f"3. Key findings and contributions\n"
        f"4. Potential implications or applications\n\n"
        f"Paper title: {title}\n\n"
        f"Abstract: {abstract}\n\n"
        f"Write the summary ENTIRELY in {lang_name}."
    )

    model = genai.GenerativeModel(_MODEL_NAME)
    response = await model.generate_content_async(prompt)
    return response.text or ""


async def analyze_pdf(pdf_url: str, language: str = "en") -> str:
    """Download a PDF and analyze it with Gemini."""
    _configure()

    lang_name = _LANGUAGE_NAMES.get(language, "English")

    # Download PDF
    async with httpx.AsyncClient(timeout=_PDF_TIMEOUT, follow_redirects=True) as client:
        resp = await client.get(pdf_url)
        resp.raise_for_status()

    content_type = resp.headers.get("content-type", "")
    if "pdf" not in content_type and not pdf_url.endswith(".pdf"):
        raise ValueError("URL does not point to a PDF file")

    pdf_bytes = resp.content
    if len(pdf_bytes) > _MAX_PDF_SIZE:
        raise ValueError(f"PDF exceeds maximum size of {_MAX_PDF_SIZE // (1024*1024)} MB")

    prompt = (
        f"You are an expert scientific research assistant.\n"
        f"Analyze the following PDF document in {lang_name}.\n"
        f"Provide a detailed analysis (5-8 paragraphs) covering:\n"
        f"1. Main research question and objectives\n"
        f"2. Methodology and experimental design\n"
        f"3. Key results and findings\n"
        f"4. Discussion and interpretation\n"
        f"5. Conclusions and future work\n"
        f"6. Strengths and limitations\n\n"
        f"Write the analysis ENTIRELY in {lang_name}."
    )

    model = genai.GenerativeModel(_MODEL_NAME)
    response = await model.generate_content_async([
        prompt,
        {"mime_type": "application/pdf", "data": pdf_bytes},
    ])
    return response.text or ""
