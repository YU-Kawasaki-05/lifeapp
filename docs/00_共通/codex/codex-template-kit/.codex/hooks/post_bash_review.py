#!/usr/bin/env python3
import json
import sys

payload = json.load(sys.stdin)
exit_code = payload.get("tool_response", {}).get("exit_code")
stdout = payload.get("tool_response", {}).get("stdout", "")
stderr = payload.get("tool_response", {}).get("stderr", "")

notes = []
if exit_code not in (0, None):
    notes.append("Previous Bash command failed; inspect stderr before continuing.")
if "warning" in stdout.lower() or "warning" in stderr.lower():
    notes.append("Previous Bash command emitted a warning.")
if "generated" in stdout.lower() or "generated" in stderr.lower():
    notes.append("Generated files may need manual review.")

if notes:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": " ".join(notes)
        }
    }))
