from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class MessageIn(BaseModel):
    role: Literal["system", "user", "assistant"] = "user"
    content: str


class SessionCreate(BaseModel):
    title: str = "default"
    system_prompt: str = ""
    tags: list[str] = Field(default_factory=list)


class SessionUpdate(BaseModel):
    title: str | None = None
    system_prompt: str | None = None


class QueryRequest(BaseModel):
    session_id: str
    message: str
    backend: str | None = None
    include_history: bool = True
    stream: bool = False
    extra_system: str = ""


class BroadcastRequest(BaseModel):
    session_id: str
    message: str
    backends: list[str] | None = None
    include_history: bool = True


class QueryResponse(BaseModel):
    session_id: str
    backend: str
    reply: str
    model: str | None = None
    usage: dict[str, Any] | None = None


class BroadcastResult(BaseModel):
    backend: str
    ok: bool
    reply: str | None = None
    error: str | None = None


class BroadcastResponse(BaseModel):
    session_id: str
    results: list[BroadcastResult]
