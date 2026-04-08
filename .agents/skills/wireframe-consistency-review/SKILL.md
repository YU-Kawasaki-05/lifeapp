---
name: wireframe-consistency-review
description: Use for reviewing consistency between wireframes and the official screen-transition and feature docs. Do not use for visual design generation.
---

# Wireframe Consistency Review

## Goal
Verify that each `SCR-*.md` wireframe file is consistent with the screen-transition diagram and feature list.

## Workflow
1. For each wireframe file in `docs/01_要件定義/wireframes/`, confirm:
   - The `SCR-*` ID matches an entry in `04_画面遷移図_screen-transition.md`.
   - The URL pattern listed matches the screen-transition doc.
   - Elements listed in the wireframe's "要素詳細" table reference FRs that exist in `03_機能一覧_feature-list.md`.
   - Navigation links (← 戻る, → 遷移先) are consistent with the transition diagram.
2. Flag any SCR IDs present in wireframes but missing from the transition diagram, or vice versa.
3. Flag any FR references in wireframes that don't exist in the feature list.

## Output
Return:
- Files checked
- Inconsistencies found (SCR-ID, file, issue type)
- Required edits
- Verdict: consistent / inconsistent

## Verification commands
```bash
rg -n "SCR-" docs/01_要件定義/wireframes/
rg -n "SCR-" docs/01_要件定義/04_画面遷移図_screen-transition.md
```
