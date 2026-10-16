"""Middleware de la API."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings


def setup_middlewares(app: FastAPI) -> None:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
