#!/usr/bin/env python3
import json
from pathlib import Path

workspace_notes = []
agents = Path("AGENTS.md")
if agents.exists():
    workspace_notes.append("Workspace has AGENTS.md; follow repository expectations before editing.")
if Path("skills").exists():
    workspace_notes.append("Repo-local skills are available. Prefer them for recurring workflows.")

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": " ".join(workspace_notes) or "No extra workspace notes."
    }
}))
