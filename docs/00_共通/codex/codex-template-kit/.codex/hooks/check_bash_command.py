#!/usr/bin/env python3
import json
import sys

payload = json.load(sys.stdin)
command = payload.get("tool_input", "")

blocked_fragments = [
    "rm -rf /",
    "mkfs",
    ":(){ :|:& };:",
    "git push --force",
]

for frag in blocked_fragments:
    if frag in command:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"Blocked dangerous command fragment: {frag}"
            }
        }))
        sys.exit(0)

# Soft guidance only
print(json.dumps({
    "systemMessage": "Before running Bash, prefer read-only inspection first unless editing is clearly required."
}))
