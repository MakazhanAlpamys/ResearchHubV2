from __future__ import annotations

from pydantic import BaseModel


class Paper(BaseModel):
    paper_id: str
    title: str
    authors: list[str] = []
    abstract: str = ""
    published_date: str | None = None
    source: str = ""
    url: str = ""
    pdf_url: str = ""


class SourceStatus(BaseModel):
    name: str
    ok: bool
    error: str | None = None


class PaperSearchResult(BaseModel):
    total: int
    page: int
    per_page: int
    has_more: bool = True
    papers: list[Paper]
    sources: list[SourceStatus] = []


class SummarizeRequest(BaseModel):
    title: str
    abstract: str
    language: str = "en"  # en | ru | kk


class SummarizeResponse(BaseModel):
    summary: str
    language: str


class AnalyzePdfRequest(BaseModel):
    pdf_url: str
    language: str = "en"  # en | ru | kk


class AnalyzePdfResponse(BaseModel):
    analysis: str
    language: str
