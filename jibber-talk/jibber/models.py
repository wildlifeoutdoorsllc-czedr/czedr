from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field

Speaker = Literal["michael", "atlas", "nova", "forge", "system", "other"]
Kind = Literal["chat", "progress", "blocker", "decision", "handoff"]
ProjectStatus = Literal[
    "planned",
    "in_progress",
    "blocked",
    "deployed",
    "paused",
    "done",
]


class ProjectCreate(BaseModel):
    slug: str = Field(min_length=2, max_length=64, pattern=r"^[a-z0-9][a-z0-9-]*$")
    name: str = Field(min_length=1, max_length=120)
    summary: str = Field(default="", max_length=2000)
    status: ProjectStatus = "planned"
    server_path: str = Field(default="", max_length=260)
    repo_url: str = Field(default="", max_length=500)


class ProjectUpdate(BaseModel):
    name: Optional[str] = Field(default=None, max_length=120)
    summary: Optional[str] = Field(default=None, max_length=2000)
    status: Optional[ProjectStatus] = None
    server_path: Optional[str] = Field(default=None, max_length=260)
    repo_url: Optional[str] = Field(default=None, max_length=500)
    next_action: Optional[str] = Field(default=None, max_length=1000)


class RoomCreate(BaseModel):
    project_slug: str = Field(min_length=2, max_length=64)
    slug: str = Field(min_length=2, max_length=64, pattern=r"^[a-z0-9][a-z0-9-]*$")
    title: str = Field(min_length=1, max_length=160)
    purpose: str = Field(default="", max_length=500)


class MessageCreate(BaseModel):
    speaker: Speaker = "other"
    speaker_label: str = Field(default="", max_length=80)
    kind: Kind = "chat"
    body: str = Field(min_length=1, max_length=20000)
    project_status: Optional[ProjectStatus] = None
    next_action: Optional[str] = Field(default=None, max_length=1000)


class ProgressPost(BaseModel):
    """Shortcut: post a progress update and optionally bump project status."""

    speaker: Speaker = "forge"
    speaker_label: str = Field(default="", max_length=80)
    body: str = Field(min_length=1, max_length=20000)
    status: Optional[ProjectStatus] = None
    next_action: Optional[str] = Field(default=None, max_length=1000)
    kind: Kind = "progress"
