from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import yaml

from interpreter.providers.openai_compat import OpenAICompatProvider, expand_env
from interpreter.providers.base import Provider

CONFIG_PATH = Path(__file__).resolve().parent.parent / "config.yaml"


def _load_yaml_config() -> dict[str, Any]:
    if not CONFIG_PATH.is_file():
        return {}
    with CONFIG_PATH.open(encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def _env_backends() -> dict[str, dict[str, Any]]:
    backends: dict[str, dict[str, Any]] = {}
    if os.getenv("OPENAI_API_KEY") or os.getenv("OPENAI_BASE_URL"):
        backends["openai"] = {
            "type": "openai_compat",
            "base_url": os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1"),
            "api_key": os.getenv("OPENAI_API_KEY", ""),
            "model": os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            "label": "OpenAI",
        }
    if os.getenv("ANTHROPIC_API_KEY"):
        bid = os.getenv("ANTHROPIC_BACKEND_ID", "anthropic")
        backends[bid] = {
            "type": "openai_compat",
            "base_url": os.getenv(
                "ANTHROPIC_BASE_URL", "https://api.openai.com/v1"
            ),
            "api_key": os.getenv("ANTHROPIC_API_KEY", ""),
            "model": os.getenv("ANTHROPIC_MODEL", "gpt-4o-mini"),
            "label": "Anthropic (compat proxy)",
        }
    ollama_url = os.getenv("OLLAMA_BASE_URL")
    if ollama_url:
        backends["ollama"] = {
            "type": "openai_compat",
            "base_url": ollama_url,
            "api_key": "ollama",
            "model": os.getenv("OLLAMA_MODEL", "llama3.2"),
            "label": "Ollama",
        }
    return backends


class BackendRouter:
    def __init__(self) -> None:
        cfg = _load_yaml_config()
        raw = dict(_env_backends())
        raw.update(cfg.get("backends") or {})
        self.default_backend = (
            cfg.get("default_backend")
            or os.getenv("DEFAULT_BACKEND")
            or (next(iter(raw)) if raw else "openai")
        )
        self._providers: dict[str, Provider] = {}
        for bid, spec in raw.items():
            self._providers[bid] = self._build(bid, spec)

    def _build(self, backend_id: str, spec: dict[str, Any]) -> Provider:
        kind = spec.get("type", "openai_compat")
        if kind != "openai_compat":
            raise ValueError(f"Unsupported backend type: {kind}")
        return OpenAICompatProvider(
            backend_id=backend_id,
            label=expand_env(str(spec.get("label", backend_id))),
            base_url=expand_env(str(spec.get("base_url", ""))),
            api_key=expand_env(str(spec.get("api_key", ""))),
            model=expand_env(str(spec.get("model", "gpt-4o-mini"))),
        )

    def list_backends(self) -> list[dict[str, str]]:
        return [
            {
                "id": p.backend_id,
                "label": p.label,
                "model": p.model,
                "default": p.backend_id == self.default_backend,
            }
            for p in self._providers.values()
        ]

    def get(self, backend_id: str | None) -> Provider:
        bid = backend_id or self.default_backend
        if bid not in self._providers:
            available = ", ".join(self._providers) or "(none configured)"
            raise KeyError(
                f"Unknown backend '{bid}'. Configured: {available}. "
                "Set OPENAI_API_KEY in .env or add config.yaml."
            )
        return self._providers[bid]

    def all_ids(self) -> list[str]:
        return list(self._providers.keys())
