# AGENTS.md

## Repository expectations
- This repository is docs-first. Prioritize updating `docs/` and related references before proposing large scaffolding.
- Keep diffs small and avoid touching unrelated files.
- Keep IDs stable when editing requirements: `FR-*`, `SCR-*`, `U-*`, `BR-*`.
- Prefer in-place edits over full rewrites to preserve decision history.

## Workflow expectations
- Use one task thread per coherent objective; fork only when the work clearly branches.
- For multi-step work, plan first, then execute, then verify.
- Move repeatable workflows into repo skills under `.agents/skills/`.
- Prefer deterministic scripts for repetitive checks over long ad-hoc prompts.
- Use Git feature-branch workflow: create `feature/*` branches, commit/push on those branches, and merge into `main` through PR.

## Verification expectations
- For code or infra changes, run the narrowest meaningful verification first.
- For docs-centric changes, run consistency checks with search before finishing:
  - `rg -n "FR-[0-9]+" docs/01_要件定義/03_機能一覧_feature-list.md`
  - `rg -n "SCR-[0-9A-Z-]+" docs/01_要件定義/wireframes docs/01_要件定義/04_画面遷移図_screen-transition.md`
- Use `./.agents/skills/backend-bugfix/scripts/verify.sh` when backend verification is needed.

## Documentation quality expectations
- If a change affects settled decisions, update `docs/00_共通/決定事項ログ_decision-log.md`.
- Keep terminology consistent with existing docs (ARDORS, タイムボクシング, コールドスタート設計).
- Keep requirements, wireframes, and decision logs synchronized.
- For research-backed claims, add source context in `docs/research/`.

## Safety expectations
- Ask before adding new production dependencies or introducing a new framework baseline.
- Avoid destructive commands unless explicitly requested.
- Prefer read-only investigation before editing.
- Do not commit or push directly to `main` / `master`.

## Directory notes
- `docs/00_共通/`: decision logs and cross-phase records.
- `docs/00_共通/codex/`: Codex setup references and source archive.
- `docs/01_要件定義/`: source of truth for requirements and transitions.
- `docs/01_要件定義/wireframes/`: screen-level `SCR-*` references.
- `docs/research/`: research evidence and rationale.
- `.agents/skills/`: repo-local skills (authoring and reuse).
