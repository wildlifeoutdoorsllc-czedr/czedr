from __future__ import annotations

import sqlite3
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
DB_PATH = DATA_DIR / "jibber.db"

# Seed inventory — what Michael asked to track / move to OneVPS
DEFAULT_PROJECTS = [
    {
        "slug": "czedr",
        "name": "Czedr",
        "summary": "Payment / fintech app + PHP API. Primary product in this repo.",
        "status": "in_progress",
        "server_path": "/var/www/czedr",
        "repo_url": "https://github.com/wildlifeoutdoorsllc-czedr/czedr",
        "next_action": "SSH to OneVPS (port 22122), then run deploy-on-server.sh so api.czedr.com is live.",
    },
    {
        "slug": "jibber-talk",
        "name": "Jibber Talk",
        "summary": "Shared board for Atlas / Nova / Forge / Michael to discuss progress.",
        "status": "in_progress",
        "server_path": "/var/www/jibber-talk",
        "repo_url": "",
        "next_action": "Deploy with scripts/deploy-jibber-on-server.sh after SSH works.",
    },
    {
        "slug": "ai-interpreter",
        "name": "AI Interpreter",
        "summary": "Local multi-backend chat router so prompts are not re-pasted.",
        "status": "deployed",
        "server_path": "/var/www/czedr/ai-interpreter (optional on VPS)",
        "repo_url": "",
        "next_action": "Use START-AI-TEAM.cmd on PC; optional VPS copy later.",
    },
    {
        "slug": "socialxads",
        "name": "SocialXads",
        "summary": "Separate repo where the Atlas nickname started. Not in this git tree.",
        "status": "paused",
        "server_path": "(separate deploy — not this VPS by default)",
        "repo_url": "",
        "next_action": "Open SocialXads folder in Cursor when that project needs work.",
    },
    {
        "slug": "cq-athletes",
        "name": "CQ Athletes",
        "summary": "Docs were on E:\\Documents\\CQ Athletes (drive often offline). Developer unknown.",
        "status": "blocked",
        "server_path": "(not on OneVPS yet — need source files)",
        "repo_url": "",
        "next_action": "When E: drive is online, copy project files into a repo or upload folder for deploy.",
    },
]


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


class JibberStore:
    def __init__(self, db_path: Path = DB_PATH) -> None:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        self.db_path = db_path
        self._init_db()
        self._seed_if_empty()

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
                CREATE TABLE IF NOT EXISTS projects (
                    slug TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    summary TEXT NOT NULL DEFAULT '',
                    status TEXT NOT NULL DEFAULT 'planned',
                    server_path TEXT NOT NULL DEFAULT '',
                    repo_url TEXT NOT NULL DEFAULT '',
                    next_action TEXT NOT NULL DEFAULT '',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS rooms (
                    id TEXT PRIMARY KEY,
                    project_slug TEXT NOT NULL,
                    slug TEXT NOT NULL,
                    title TEXT NOT NULL,
                    purpose TEXT NOT NULL DEFAULT '',
                    created_at TEXT NOT NULL,
                    UNIQUE(project_slug, slug),
                    FOREIGN KEY (project_slug) REFERENCES projects(slug)
                );
                CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    room_id TEXT NOT NULL,
                    speaker TEXT NOT NULL,
                    speaker_label TEXT NOT NULL DEFAULT '',
                    kind TEXT NOT NULL DEFAULT 'chat',
                    body TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (room_id) REFERENCES rooms(id)
                );
                CREATE INDEX IF NOT EXISTS idx_messages_room
                    ON messages(room_id, id);
                """
            )

    def _seed_if_empty(self) -> None:
        with self._conn() as conn:
            count = conn.execute("SELECT COUNT(*) AS c FROM projects").fetchone()["c"]
        if count:
            return
        now = _utc_now()
        for p in DEFAULT_PROJECTS:
            self.create_project(
                slug=p["slug"],
                name=p["name"],
                summary=p["summary"],
                status=p["status"],
                server_path=p["server_path"],
                repo_url=p["repo_url"],
                next_action=p["next_action"],
                created_at=now,
            )
            room = self.create_room(
                project_slug=p["slug"],
                slug="progress",
                title=f"{p['name']} — progress",
                purpose="Status updates and next actions for AIs and Michael.",
            )
            self.add_message(
                room_id=room["id"],
                speaker="system",
                speaker_label="Jibber",
                kind="handoff",
                body=(
                    f"Room opened for **{p['name']}**.\n\n"
                    f"Status: `{p['status']}`\n"
                    f"Server path: `{p['server_path'] or 'TBD'}`\n"
                    f"Next: {p['next_action']}"
                ),
            )
        general = self.create_room(
            project_slug="jibber-talk",
            slug="war-room",
            title="War room — all projects",
            purpose="Cross-project jibber between Atlas, Nova, Forge, and Michael.",
        )
        self.add_message(
            room_id=general["id"],
            speaker="atlas",
            speaker_label="Atlas",
            kind="handoff",
            body=(
                "Welcome to Jibber Talk.\n\n"
                "Use this board so later AIs can see progress without re-explaining everything.\n"
                "One step for Michael: get SSH working on port **22122**, then we deploy "
                "Czedr + this board to the OneVPS box."
            ),
        )

    def create_project(
        self,
        *,
        slug: str,
        name: str,
        summary: str = "",
        status: str = "planned",
        server_path: str = "",
        repo_url: str = "",
        next_action: str = "",
        created_at: Optional[str] = None,
    ) -> dict[str, Any]:
        now = created_at or _utc_now()
        with self._conn() as conn:
            conn.execute(
                """
                INSERT INTO projects
                (slug, name, summary, status, server_path, repo_url, next_action, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (slug, name, summary, status, server_path, repo_url, next_action, now, now),
            )
        return self.get_project(slug)

    def get_project(self, slug: str) -> dict[str, Any]:
        with self._conn() as conn:
            row = conn.execute(
                "SELECT * FROM projects WHERE slug = ?", (slug,)
            ).fetchone()
        if not row:
            raise KeyError(slug)
        return dict(row)

    def list_projects(self) -> list[dict[str, Any]]:
        with self._conn() as conn:
            rows = conn.execute(
                "SELECT * FROM projects ORDER BY name COLLATE NOCASE"
            ).fetchall()
        return [dict(r) for r in rows]

    def update_project(self, slug: str, **fields: Any) -> dict[str, Any]:
        allowed = {
            "name",
            "summary",
            "status",
            "server_path",
            "repo_url",
            "next_action",
        }
        updates = {k: v for k, v in fields.items() if k in allowed and v is not None}
        if not updates:
            return self.get_project(slug)
        updates["updated_at"] = _utc_now()
        cols = ", ".join(f"{k} = ?" for k in updates)
        vals = list(updates.values()) + [slug]
        with self._conn() as conn:
            cur = conn.execute(
                f"UPDATE projects SET {cols} WHERE slug = ?", vals
            )
            if cur.rowcount == 0:
                raise KeyError(slug)
        return self.get_project(slug)

    def create_room(
        self,
        *,
        project_slug: str,
        slug: str,
        title: str,
        purpose: str = "",
    ) -> dict[str, Any]:
        self.get_project(project_slug)
        rid = str(uuid.uuid4())
        now = _utc_now()
        with self._conn() as conn:
            conn.execute(
                """
                INSERT INTO rooms (id, project_slug, slug, title, purpose, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (rid, project_slug, slug, title, purpose, now),
            )
        return self.get_room(rid)

    def get_room(self, room_id: str) -> dict[str, Any]:
        with self._conn() as conn:
            row = conn.execute(
                "SELECT * FROM rooms WHERE id = ?", (room_id,)
            ).fetchone()
        if not row:
            raise KeyError(room_id)
        return dict(row)

    def get_room_by_slugs(self, project_slug: str, room_slug: str) -> dict[str, Any]:
        with self._conn() as conn:
            row = conn.execute(
                "SELECT * FROM rooms WHERE project_slug = ? AND slug = ?",
                (project_slug, room_slug),
            ).fetchone()
        if not row:
            raise KeyError(f"{project_slug}/{room_slug}")
        return dict(row)

    def list_rooms(self, project_slug: Optional[str] = None) -> list[dict[str, Any]]:
        with self._conn() as conn:
            if project_slug:
                rows = conn.execute(
                    "SELECT * FROM rooms WHERE project_slug = ? ORDER BY title COLLATE NOCASE",
                    (project_slug,),
                ).fetchall()
            else:
                rows = conn.execute(
                    "SELECT * FROM rooms ORDER BY project_slug, title COLLATE NOCASE"
                ).fetchall()
        return [dict(r) for r in rows]

    def add_message(
        self,
        *,
        room_id: str,
        speaker: str,
        body: str,
        kind: str = "chat",
        speaker_label: str = "",
    ) -> dict[str, Any]:
        self.get_room(room_id)
        now = _utc_now()
        with self._conn() as conn:
            cur = conn.execute(
                """
                INSERT INTO messages (room_id, speaker, speaker_label, kind, body, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (room_id, speaker, speaker_label, kind, body, now),
            )
            mid = cur.lastrowid
            row = conn.execute(
                "SELECT * FROM messages WHERE id = ?", (mid,)
            ).fetchone()
        return dict(row)

    def list_messages(
        self, room_id: str, *, limit: int = 200, after_id: int = 0
    ) -> list[dict[str, Any]]:
        limit = max(1, min(limit, 500))
        with self._conn() as conn:
            rows = conn.execute(
                """
                SELECT * FROM messages
                WHERE room_id = ? AND id > ?
                ORDER BY id ASC
                LIMIT ?
                """,
                (room_id, after_id, limit),
            ).fetchall()
        return [dict(r) for r in rows]

    def export_markdown(self, room_id: str) -> str:
        room = self.get_room(room_id)
        project = self.get_project(room["project_slug"])
        msgs = self.list_messages(room_id, limit=500)
        lines = [
            f"# {room['title']}",
            "",
            f"**Project:** {project['name']} (`{project['slug']}`) — status `{project['status']}`",
            f"**Next action:** {project.get('next_action') or '(none)'}",
            f"**Server path:** `{project.get('server_path') or 'TBD'}`",
            "",
            "---",
            "",
        ]
        for m in msgs:
            label = m["speaker_label"] or m["speaker"]
            lines.append(f"### {label} · {m['kind']} · {m['created_at']}")
            lines.append("")
            lines.append(m["body"])
            lines.append("")
        return "\n".join(lines)
