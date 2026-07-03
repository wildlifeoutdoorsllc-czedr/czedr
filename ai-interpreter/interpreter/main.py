from __future__ import annotations

import asyncio
import os
from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from interpreter.models import (
    BroadcastRequest,
    BroadcastResponse,
    BroadcastResult,
    MessageIn,
    QueryRequest,
    QueryResponse,
    SessionCreate,
    SessionUpdate,
)
from interpreter.router import BackendRouter
from interpreter.store import SessionStore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

store = SessionStore()
router = BackendRouter()
STATIC = Path(__file__).resolve().parent.parent / "static"
API_KEY = os.getenv("INTERPRETER_API_KEY", "")


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
    title="AI Interpreter",
    description="Central session store + multi-backend query routing",
    version="1.0.0",
    lifespan=lifespan,
)

if STATIC.is_dir():
    app.mount("/ui", StaticFiles(directory=STATIC, html=True), name="ui")


@app.get("/")
def root():
    if (STATIC / "index.html").is_file():
        return FileResponse(STATIC / "index.html")
    return {"service": "ai-interpreter", "docs": "/docs", "ui": "/ui/"}


@app.get("/v1/health")
def health():
    return {
        "ok": True,
        "backends": router.list_backends(),
        "default_backend": router.default_backend,
    }


@app.get("/v1/sessions")
def list_sessions(
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    return {"sessions": store.list_sessions()}


@app.post("/v1/sessions")
def create_session(
    body: SessionCreate,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    session = store.create_session(
        title=body.title,
        system_prompt=body.system_prompt,
        tags=body.tags,
    )
    return session


@app.patch("/v1/sessions/{session_id}")
def update_session(
    session_id: str,
    body: SessionUpdate,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        session = store.update_session(
            session_id,
            title=body.title,
            system_prompt=body.system_prompt,
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    return session


@app.get("/v1/sessions/{session_id}")
def get_session(
    session_id: str,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        session = store.get_session(session_id)
        messages = store.get_messages(session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"session": session, "messages": messages}


@app.get("/v1/sessions/{session_id}/export")
def export_session(
    session_id: str,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        md = store.export_markdown(session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"markdown": md}


@app.post("/v1/sessions/{session_id}/messages")
def append_message(
    session_id: str,
    body: MessageIn,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        msg = store.add_message(session_id, body.role, body.content)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")
    return msg


@app.post("/v1/query", response_model=QueryResponse)
async def query(
    body: QueryRequest,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        store.get_session(body.session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")

    store.add_message(body.session_id, "user", body.message)

    messages = []
    if body.include_history:
        messages = store.build_chat_messages(body.session_id, body.extra_system)
    else:
        if body.extra_system:
            messages.append({"role": "system", "content": body.extra_system})
        messages.append({"role": "user", "content": body.message})

    try:
        provider = router.get(body.backend)
    except KeyError as e:
        raise HTTPException(status_code=400, detail=str(e))

    try:
        result = await provider.complete(messages)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Backend error: {e}")

    reply = result["reply"]
    store.add_message(
        body.session_id, "assistant", reply, backend=provider.backend_id
    )

    return QueryResponse(
        session_id=body.session_id,
        backend=provider.backend_id,
        reply=reply,
        model=result.get("model"),
        usage=result.get("usage"),
    )


@app.post("/v1/broadcast", response_model=BroadcastResponse)
async def broadcast(
    body: BroadcastRequest,
    authorization: str | None = Header(None),
    x_api_key: str | None = Header(None, alias="X-API-Key"),
):
    _check_auth(authorization, x_api_key)
    try:
        store.get_session(body.session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="Session not found")

    store.add_message(body.session_id, "user", body.message)
    messages = store.build_chat_messages(body.session_id) if body.include_history else [
        {"role": "user", "content": body.message}
    ]

    backend_ids = body.backends or router.all_ids()
    if not backend_ids:
        raise HTTPException(status_code=400, detail="No backends configured")

    async def run_one(bid: str) -> BroadcastResult:
        try:
            provider = router.get(bid)
            result = await provider.complete(messages)
            reply = result["reply"]
            store.add_message(
                body.session_id, "assistant", f"[{bid}]\n{reply}", backend=bid
            )
            return BroadcastResult(backend=bid, ok=True, reply=reply)
        except Exception as e:
            return BroadcastResult(backend=bid, ok=False, error=str(e))

    results = await asyncio.gather(*[run_one(b) for b in backend_ids])
    return BroadcastResponse(session_id=body.session_id, results=list(results))
