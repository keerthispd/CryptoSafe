from __future__ import annotations

import os
from pathlib import Path

from web_app.app import app, init_db


def main() -> int:
    repo_root = Path(__file__).resolve().parent
    print(f"Serving from: {repo_root / 'web_app'}")
    print(f"Using database: {app.config.get('DATABASE_PATH', os.environ.get('DATABASE_PATH', str(repo_root / 'web_app' / 'cryptosafe.db')))}")
    init_db()
    app.run(
        debug=os.environ.get("FLASK_DEBUG", "1").strip().lower() in {"1", "true", "yes", "on"},
        host=os.environ.get("HOST", "0.0.0.0"),
        port=int(os.environ.get("PORT", "5000")),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())