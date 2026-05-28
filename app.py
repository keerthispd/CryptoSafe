from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parent
    venv_python = repo_root / ".venv" / "Scripts" / "python.exe"
    target_app = repo_root / "web_app" / "app.py"

    if venv_python.exists():
        completed = subprocess.run([str(venv_python), str(target_app)])
        return completed.returncode

    print(f"Virtual environment Python not found at {venv_python}")
    print("Run the app with an activated virtual environment or recreate .venv.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())