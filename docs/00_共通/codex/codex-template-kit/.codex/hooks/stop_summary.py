#!/usr/bin/env python3
import json
from pathlib import Path
from datetime import datetime

out_dir = Path(".codex")
out_dir.mkdir(exist_ok=True)
summary_file = out_dir / "last_stop_summary.txt"
summary_file.write_text(
    f"Session stopped at {datetime.utcnow().isoformat()}Z\n"
    "Review recent diffs, test results, and any pending risks before the next session.\n",
    encoding="utf-8",
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "Stop",
        "additionalContext": "Wrote .codex/last_stop_summary.txt"
    }
}))
