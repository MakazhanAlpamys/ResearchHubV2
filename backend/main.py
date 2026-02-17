"""ResearchHubV2 – FastAPI Backend."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import papers, ai

settings = get_settings()

app = FastAPI(
    title="ResearchHubV2 API",
    version="1.0.0",
    docs_url="/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(papers.router, prefix="/api")
app.include_router(ai.router, prefix="/api")


@app.get("/health")
async def health():
    return {"status": "ok"}
