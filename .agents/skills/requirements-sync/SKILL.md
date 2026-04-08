---
name: requirements-sync
description: Use when requirements docs are edited and you need to validate cross-document consistency for FR/SCR/BR/U IDs and decision-log alignment. Do not use for code implementation tasks.
---

# Requirements Sync

## Goal
Ensure all requirement documents remain internally consistent after any edit.

## Workflow
1. Identify all documents that may be affected by the change.
2. Check ID stability: no FR/SCR/BR/U ID was silently renamed or removed.
3. Verify cross-references are intact:
   - `03_機能一覧_feature-list.md` ↔ `04_画面遷移図_screen-transition.md`
   - `04_画面遷移図_screen-transition.md` ↔ `wireframes/SCR-*.md`
   - `05_受入基準_acceptance-criteria.md` ↔ `03_機能一覧_feature-list.md`
4. Check `決定事項ログ_decision-log.md` for any decision impacted by the change.
5. Report all inconsistencies with file paths and line references.

## Output
Return:
- Documents checked
- Inconsistencies found (with file:line)
- Required edits
- Verdict: consistent / inconsistent

## Verification commands
```bash
rg -n "FR-[0-9]+" docs/01_要件定義/03_機能一覧_feature-list.md
rg -n "SCR-[0-9A-Z-]+" docs/01_要件定義/wireframes docs/01_要件定義/04_画面遷移図_screen-transition.md
```
