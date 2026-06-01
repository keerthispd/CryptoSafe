from __future__ import annotations

import os
import sqlite3
import warnings
from pathlib import Path

# Try importing common SQLCipher bindings. If not present, we'll fall back to plain sqlite3
# but emit a clear warning so the operator can install the bindings for true encryption.
sqlcipher_dbapi = None
for mod in ("sqlcipher3.dbapi2", "pysqlcipher3.dbapi2"):
    try:
        __import__(mod)
        sqlcipher_dbapi = __import__(mod, fromlist=["dbapi2"]).dbapi2
        break
    except Exception:
        sqlcipher_dbapi = None


def resolve_sqlcipher_key() -> str:
    for env_name in ("SQLCIPHER_KEY", "DATABASE_KEY", "DATABASE_PASSWORD"):
        value = os.environ.get(env_name, "").strip()
        if value:
            return value
    return os.environ.get("SECRET_KEY", "dev-secret-key-change-me")


def _is_plaintext_sqlite(db_path: Path) -> bool:
    if not db_path.exists() or not db_path.is_file():
        return False
    with db_path.open("rb") as handle:
        return handle.read(16) == b"SQLite format 3\x00"


def _pragma_key_statement(key: str) -> str:
    escaped = key.replace("'", "''")
    return f"PRAGMA key = '{escaped}'"


def migrate_plaintext_database(db_path: Path, key: str) -> None:
    if sqlcipher_dbapi is None:
        warnings.warn(
            "SQLCipher bindings not available; skipping plaintext->SQLCipher migration.",
            RuntimeWarning,
        )
        return
    if not _is_plaintext_sqlite(db_path):
        return

    backup_path = db_path.with_suffix(db_path.suffix + ".plaintext-backup")
    temp_path = db_path.with_suffix(db_path.suffix + ".sqlcipher-tmp")

    if temp_path.exists():
        temp_path.unlink()

    with sqlite3.connect(db_path) as plaintext_conn:
        plaintext_conn.row_factory = sqlite3.Row
        with sqlcipher_dbapi.connect(str(temp_path), timeout=30, check_same_thread=False) as cipher_conn:
            cipher_conn.execute(_pragma_key_statement(key))
            cipher_conn.execute("PRAGMA cipher_compatibility = 4")
            cipher_conn.execute("PRAGMA foreign_keys = OFF")
            cipher_conn.executescript("\n".join(plaintext_conn.iterdump()))
            cipher_conn.commit()

    if backup_path.exists():
        backup_path.unlink()
    db_path.replace(backup_path)
    temp_path.replace(db_path)


def open_sqlcipher_database(db_path: Path, key: str):
    db_path.parent.mkdir(parents=True, exist_ok=True)
    # Only attempt to migrate if we have real SQLCipher support
    migrate_plaintext_database(db_path, key)

    if sqlcipher_dbapi is None:
        warnings.warn(
            "SQLCipher Python bindings not found; opening plaintext SQLite database. "
            "Install sqlcipher3/pysqlcipher3 to enable DB encryption.",
            RuntimeWarning,
        )
        conn = sqlite3.connect(str(db_path), timeout=30, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA busy_timeout=30000")
        conn.execute("PRAGMA foreign_keys=ON")
        return conn

    conn = sqlcipher_dbapi.connect(str(db_path), timeout=30, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute(_pragma_key_statement(key))
    conn.execute("PRAGMA cipher_compatibility = 4")
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=30000")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn