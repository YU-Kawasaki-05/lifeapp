---
name: connect-actions
description: Use when the user wants Codex to take real actions via external app/connectors (mail, chat, tickets, docs). Use only with explicit user intent and confirm destructive actions.
---

# Connect Actions

## Goal
Execute real-world actions through external integrations on behalf of the user.

## Workflow
1. Confirm the exact action the user wants to take and its target.
2. Identify whether the action is reversible or destructive.
3. For destructive or irreversible actions, state the action and ask for explicit confirmation before executing.
4. Execute the action and report the result.
5. Surface any failures, partial completions, or side effects.

## Output
Return:
- Action taken (or refused, with reason)
- Result or error
- Any follow-up steps needed

## Guardrails
- Never send messages, create tickets, or modify external state without explicit user confirmation.
- If scope is ambiguous, clarify first.
- Prefer dry-run or preview modes when available.
