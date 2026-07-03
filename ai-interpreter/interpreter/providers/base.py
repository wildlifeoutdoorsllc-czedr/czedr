from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any


class Provider(ABC):
    def __init__(self, backend_id: str, label: str, model: str) -> None:
        self.backend_id = backend_id
        self.label = label
        self.model = model

    @abstractmethod
    async def complete(self, messages: list[dict[str, str]]) -> dict[str, Any]:
        """Return {reply, model, usage}."""
