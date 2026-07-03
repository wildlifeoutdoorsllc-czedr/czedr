from __future__ import annotations

import os
from typing import Any

import httpx

from interpreter.providers.base import Provider


class OpenAICompatProvider(Provider):
    def __init__(
        self,
        backend_id: str,
        label: str,
        base_url: str,
        api_key: str,
        model: str,
        timeout: float = 120.0,
    ) -> None:
        super().__init__(backend_id, label, model)
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.timeout = timeout

    async def complete(self, messages: list[dict[str, str]]) -> dict[str, Any]:
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": 0.7,
        }
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            resp = await client.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
            )
            resp.raise_for_status()
            data = resp.json()
        choice = data["choices"][0]["message"]
        return {
            "reply": choice.get("content") or "",
            "model": data.get("model", self.model),
            "usage": data.get("usage"),
        }


def expand_env(value: str) -> str:
    if not value:
        return value
    out = value
    for key, val in os.environ.items():
        out = out.replace(f"${{{key}}}", val)
    return out
