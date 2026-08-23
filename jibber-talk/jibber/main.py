from __future__ import annotations

import os
from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Query
from fastapi.responses import FileResponse, PlainTextResponse
from fastapi.staticfiles import StaticFiles

from jibber.models import (
    MessageCreate,
    ProgressPost,
    ProjectCreate,
    ProjectUpdate,
    RoomCreate,
)
from jibber.store import JibberStore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

store = JibberStore()
STATIC = Path(__file__).resolve().parent.parent / "static"
API_KEY = os.getenv("JIBBER_API_KEY", "").strip()


def _check_auth(authorization: str | None, x_api_key: str | None) -> None:
    if not API_KEY:
        return
    token = ""
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization[7:].strip()
    elif x_api_key:
        token = x_api_key.strip()
    if token != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")


@asynccontextmanager
async def lifespan(_app: FastAPI):
    yield


app = FastAPI(
    title="Jibber Talk",
    description="Shared progress board for Michael and AI teammates (Atlas, Nova, Forge).",
    version="1.0.0",
    lifespan=lifespan,
)

if STATIC.is_dir():
    app.mount("/ui", StaticFiles(directory=STATIC, html=True), name="ui")


@app.get("/")
def root():
    if (STATIC / "index.html").is_file():
        return FileResponse(STATIC / "index.html")
    return {"service": "jibber-talk", "docs": "/docs"}


@app.get("/v1/health")
def health():
    return {
        "ok": True,
        "service": "jibber-talk",
        "projects": len(store.list_projects()),
        "auth_required": bool(API_KEY),
    }


@app.get("/v1/projects")
def list_projects(
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    return {"projects": store.list_projects()}


@app.post("/v1/projects")
def create_project(
    body: ProjectCreate,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        store.get_project(body.slug)
        raise HTTPException(status_code=409, detail="Project already exists")
    except KeyError:
        pass
    project = store.create_project(
        slug=body.slug,
        name=body.name,
        summary=body.summary,
        status=body.status,
        server_path=body.server_path,
        repo_url=body.repo_url,
    )
    store.create_room(
        project_slug=body.slug,
        slug="progress",
        title=f"{body.name} — progress",
        purpose="Status updates and next actions.",
    )
    return project


@app.get("/v1/projects/{slug}")
def get_project(
    slug: str,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        return store.get_project(slug)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Project not found") from exc


@app.patch("/v1/projects/{slug}")
def patch_project(
    slug: str,
    body: ProjectUpdate,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        return store.update_project(slug, **body.model_dump(exclude_unset=True))
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Project not found") from exc


@app.get("/v1/rooms")
def list_rooms(
    project: str | None = Query(None),
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    return {"rooms": store.list_rooms(project)}


@app.post("/v1/rooms")
def create_room(
    body: RoomCreate,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        return store.create_room(
            project_slug=body.project_slug,
            slug=body.slug,
            title=body.title,
            purpose=body.purpose,
        )
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Project not found") from exc
    except Exception as exc:  # noqa: BLE001 — surface unique constraint cleanly
        if "UNIQUE" in str(exc).upper():
            raise HTTPException(status_code=409, detail="Room already exists") from exc
        raise


@app.get("/v1/rooms/{room_id}")
def get_room(
    room_id: str,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        return store.get_room(room_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Room not found") from exc


@app.get("/v1/projects/{project_slug}/rooms/{room_slug}")
def get_room_by_slug(
    project_slug: str,
    room_slug: str,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        return store.get_room_by_slugs(project_slug, room_slug)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Room not found") from exc


@app.get("/v1/rooms/{room_id}/messages")
def list_messages(
    room_id: str,
    limit: int = Query(200, ge=1, le=500),
    after_id: int = Query(0, ge=0),
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        store.get_room(room_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Room not found") from exc
    return {"messages": store.list_messages(room_id, limit=limit, after_id=after_id)}


@app.post("/v1/rooms/{room_id}/messages")
def post_message(
    room_id: str,
    body: MessageCreate,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        room = store.get_room(room_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Room not found") from exc

    msg = store.add_message(
        room_id=room_id,
        speaker=body.speaker,
        speaker_label=body.speaker_label,
        kind=body.kind,
        body=body.body,
    )
    if body.project_status or body.next_action:
        store.update_project(
            room["project_slug"],
            status=body.project_status,
            next_action=body.next_action,
        )
    return msg


@app.post("/v1/projects/{slug}/progress")
def post_progress(
    slug: str,
    body: ProgressPost,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    """Post into the project's `progress` room and optionally update status."""
    _check_auth(authorization, x_api_key)
    try:
        store.get_project(slug)
        room = store.get_room_by_slugs(slug, "progress")
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Project or progress room not found") from exc

    msg = store.add_message(
        room_id=room["id"],
        speaker=body.speaker,
        speaker_label=body.speaker_label,
        kind=body.kind,
        body=body.body,
    )
    if body.status or body.next_action:
        store.update_project(
            slug,
            status=body.status,
            next_action=body.next_action,
        )
    return {
        "message": msg,
        "project": store.get_project(slug),
    }


@app.get("/v1/rooms/{room_id}/export")
def export_room(
    room_id: str,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        md = store.export_markdown(room_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Room not found") from exc
    return PlainTextResponse(md, media_type="text/markdown; charset=utf-8")
