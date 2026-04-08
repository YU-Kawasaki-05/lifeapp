# Community Sources (Non-Official)

This file tracks non-official references adopted for experimentation and productivity gains.

## Adopted ideas

1. ComposioHQ/awesome-codex-skills
- URL: `https://github.com/ComposioHQ/awesome-codex-skills`
- Adopted concepts:
  - Plan-first skill structure (`create-plan`)
  - GitHub CI triage workflow (`gh-fix-ci`)
  - Connector action execution pattern (`connect`)
- Local adaptation:
  - Implemented as repo-local variants in `.agents/skills/` and tailored to ARDORS workflows.

2. feiskyer/codex-settings
- URL: `https://github.com/feiskyer/codex-settings`
- Adopted concepts:
  - Multi-profile config operation (`fast`, `review`, `explore`)
  - Practical Codex config layering for daily workflows
- Local adaptation:
  - Applied only profile and workflow ideas; no direct config copy.

3. pre-commit/pre-commit + pre-commit/pre-commit-hooks
- URL:
  - `https://pre-commit.com/`
  - `https://github.com/pre-commit/pre-commit-hooks`
- Adopted concepts:
  - `no-commit-to-branch` for protected branch workflow
  - `detect-private-key` and lightweight quality hooks
  - consistent local hook orchestration across environments
- Local adaptation:
  - Added `/.pre-commit-config.yaml`
  - Added local `pre-push` hook script: `/.githooks/pre_push_protect_main.sh`
  - protected branch push is blocked by default locally, bypass only via explicit `--no-verify` after human approval

## Evaluation policy
- Prefer official OpenAI guidance first.
- Treat community skills as optional accelerators.
- For high-risk actions (delete/update external systems), require explicit user confirmation.
