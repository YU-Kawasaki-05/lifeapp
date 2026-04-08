# AGENTS.md

## Repository expectations
- Prefer `pnpm` over `npm` unless this repository explicitly requires otherwise.
- Keep diffs small and avoid touching unrelated files.
- Run the most relevant lint and test commands before finishing.
- Do not change public interfaces without updating docs and tests.

## Review expectations
- Lead with root cause, not just the patch.
- For bug fixes, add or update tests whenever practical.
- Call out risk, assumptions, and files changed.

## Safety and approval expectations
- Ask before adding new production dependencies.
- Avoid destructive commands unless the user explicitly asked for them.
- Prefer read-only investigation before editing.

## Directory notes
- `apps/web/`: frontend-only changes unless API contract updates are required.
- `packages/api/`: do not rename exported types without clear justification.
- `infra/`: treat as high-risk; prefer review-first changes.
