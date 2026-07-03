from __future__ import annotations

import json
import sqlite3
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
DB_PATH = DATA_DIR / "interpreter.db"


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


class SessionStore:
    def __init__(self, db_path: Path = DB_PATH) -> None:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        self.db_path = db_path
        self._init_db()

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    def _init_db(self) -> None:
        with self._conn() as conn:
            conn.executescript(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    system_prompt TEXT NOT NULL DEFAULT '',
                    tags TEXT NOT NULL DEFAULT '[]',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id TEXT NOT NULL,
                    role TEXT NOT NULL,
                    content TEXT NOT NULL,
                    backend TEXT,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (session_id) REFERENCES sessions(id)
                );
                CREATE INDEX IF NOT EXISTS idx_messages_session
                    ON messages(session_id, id);
                """
            )

    def create_session(
        self, title: str, system_prompt: str = "", tags: list[str] | None = None
    ) -> dict[str, Any]:
        sid = str(uuid.uuid4())
        now = _utc_now()
        tags_json = json.dumps(tags or [])
        with self._conn() as conn:
            conn.execute(
                """
                INSERT INTO sessions (id, title, system_prompt, tags, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (sid, title, system_prompt, tags_json, now, now),
            )
        return self.get_session(sid)

    def get_session(self, session_id: str) -> dict[str, Any]:
        with self._conn() as conn:
            row = conn.execute(
                "SELECT * FROM sessions WHERE id = ?", (session_id,)
            ).fetchone()
        if not row:
            raise KeyError(f"Session not found: {session_id}")
        return {
            "id": row["id"],
            "title": row["title"],
            "system_prompt": row["system_prompt"],
            "tags": json.loads(row["tags"]),
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
        }

    def list_sessions(self, limit: int = 50) -> list[dict[str, Any]]:
        with self._conn() as conn:
            rows = conn.execute(
                """
                SELECT s.*, COUNT(m.id) AS message_count
                FROM sessions s
                LEFT JOIN messages m ON m.session_id = s.id
                GROUP BY s.id
                ORDER BY s.updated_at DESC
                LIMIT ?
                """,
                (limit,),
            ).fetchall()
        return [
            {
                **self._session_row(r),
                "message_count": r["message_count"],
            }
            for r in rows
        ]

    def _session_row(self, row: sqlite3.Row) -> dict[str, Any]:
        return {
            "id": row["id"],
            "title": row["title"],
            "system_prompt": row["system_prompt"],
            "tags": json.loads(row["tags"]),
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
        }

    def touch_session(self, session_id: str) -> None:
        with self._conn() as conn:
            conn.execute(
                "UPDATE sessions SET updated_at = ? WHERE id = ?",
                (_utc_now(), session_id),
            )

    def update_session(
        self,
        session_id: str,
        *,
        title: str | None = None,
        system_prompt: str | None = None,
    ) -> dict[str, Any]:
        session = self.get_session(session_id)
        new_title = title if title is not None else session["title"]
        new_system = (
            system_prompt if system_prompt is not None else session["system_prompt"]
        )
        now = _utc_now()
        with self._conn() as conn:
            conn.execute(
                """
                UPDATE sessions SET title = ?, system_prompt = ?, updated_at = ?
                WHERE id = ?
                """,
                (new_title, new_system, now, session_id),
            )
        return self.get_session(session_id)

    def add_message(
        self,
        session_id: str,
        role: str,
        content: str,
        backend: str | None = None,
    ) -> dict[str, Any]:
        self.get_session(session_id)
        now = _utc_now()
        with self._conn() as conn:
            cur = conn.execute(
                """
                INSERT INTO messages (session_id, role, content, backend, created_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                (session_id, role, content, backend, now),
            )
            msg_id = cur.lastrowid
            conn.execute(
                "UPDATE sessions SET updated_at = ? WHERE id = ?",
                (now, session_id),
            )
        return {
            "id": msg_id,
            "session_id": session_id,
            "role": role,
            "content": content,
            "backend": backend,
            "created_at": now,
        }

    def get_messages(self, session_id: str) -> list[dict[str, Any]]:
        self.get_session(session_id)
        with self._conn() as conn:
            rows = conn.execute(
                """
                SELECT id, session_id, role, content, backend, created_at
                FROM messages WHERE session_id = ?
                ORDER BY id ASC
                """,
                (session_id,),
            ).fetchall()
        return [dict(r) for r in rows]

    def build_chat_messages(
        self,
        session_id: str,
        extra_system: str = "",
    ) -> list[dict[str, str]]:
        session = self.get_session(session_id)
        history = self.get_messages(session_id)
        out: list[dict[str, str]] = []
        system_parts = [p for p in (session["system_prompt"], extra_system) if p.strip()]
        if system_parts:
            out.append({"role": "system", "content": "\n\n".join(system_parts)})
        for m in history:
            out.append({"role": m["role"], "content": m["content"]})
        return out

    def export_markdown(self, session_id: str) -> str:
        session = self.get_session(session_id)
        messages = self.get_messages(session_id)
        lines = [
            f"# {session['title']}",
            "",
            f"Session: `{session_id}`",
            "",
        ]
        if session["system_prompt"].strip():
            lines.extend(["## System context", "", session["system_prompt"], ""])
        lines.append("## Conversation")
        lines.append("")
        for m in messages:
            role = m["role"].capitalize()
            backend = f" ({m['backend']})" if m.get("backend") else ""
            lines.append(f"### {role}{backend}")
            lines.append("")
            lines.append(m["content"])
            lines.append("")
        return "\n".join(lines)
