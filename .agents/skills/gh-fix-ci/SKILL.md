---
name: gh-fix-ci
description: Use when a user asks to investigate or fix failing GitHub PR checks using gh CLI, including summarizing failing jobs and proposing a concrete fix plan.
---

# Fix CI

## Goal
Diagnose and fix failing GitHub Actions CI checks with the smallest targeted change.

## Workflow
1. Fetch the failing run details with `gh run view` or `gh pr checks`.
2. Identify the failing job(s) and step(s).
3. Read the relevant log output to determine root cause.
4. Propose a concrete fix (config change, dependency pin, test update, etc.).
5. After fixing, verify the same check passes locally where possible.

## Output
Return:
- Failing job summary
- Root cause
- Fix applied (file and change)
- Verification performed
- Residual risk if any

## Resources
```bash
gh run list --limit 5
gh run view <run-id> --log-failed
gh pr checks <pr-number>
```
