---
name: doc-change-risk-check
description: Use before or after major requirement-doc updates to evaluate regression risk, hidden coupling, and rollout impact. Do not use for implementation-only bugfixes.
---

# Doc Change Risk Check

## Goal
Identify downstream risk when requirement documents change — catch hidden coupling before it becomes a bug.

## Workflow
1. Identify which documents changed and what IDs were affected (FR-*, SCR-*, BR-*, U-*).
2. Search for all references to those IDs across the repository.
3. Check whether wireframes, screen-transition, feature-list, and acceptance-criteria are still consistent.
4. Flag any mismatches, orphaned references, or cascade changes needed.
5. Summarize risk level and required follow-up edits.

## Output
Return:
- Changed IDs and their propagation scope
- Consistency issues found
- Required follow-up edits (with file paths)
- Risk level: low / medium / high

## Resources
- Run `rg -n "FR-[0-9]+" docs/` to locate all FR references.
- Run `rg -n "SCR-[0-9A-Z-]+" docs/` to locate all SCR references.
- Cross-check `docs/00_共通/決定事項ログ_decision-log.md` for impacted decisions.
