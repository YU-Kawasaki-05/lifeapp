#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-${REPO_ROOT}/.codex-home}"
PROMPTS_DIR="${CODEX_HOME_DIR}/prompts"

mkdir -p "${PROMPTS_DIR}"
echo "prompt install target: ${PROMPTS_DIR}"

PROMPT_IDS=(
  "req-phase1"
  "req-phase2"
  "req-phase3"
)

SOURCE_FILES=(
  ".claude/commands/要件定義/01_phase1_hearing_and_requirements_agent.md"
  ".claude/commands/要件定義/02_phase2_external_design_agent.md"
  ".claude/commands/要件定義/03_phase3_technical_design_agent.md"
)

DESCRIPTIONS=(
  "Run Phase 1 hearing and requirements workflow from .claude/commands."
  "Run Phase 2 external design workflow from .claude/commands."
  "Run Phase 3 technical design workflow from .claude/commands."
)

ARG_HINTS=(
  "[DOCS_ROOT=./docs] [PROJECT_NAME=<name>]"
  "[DOCS_ROOT=./docs]"
  "[DOCS_ROOT=./docs]"
)

for i in "${!PROMPT_IDS[@]}"; do
  prompt_id="${PROMPT_IDS[$i]}"
  source_rel="${SOURCE_FILES[$i]}"
  source_abs="${REPO_ROOT}/${source_rel}"
  description="${DESCRIPTIONS[$i]}"
  arg_hint="${ARG_HINTS[$i]}"
  prompt_file="${PROMPTS_DIR}/${prompt_id}.md"

  if [[ ! -f "${source_abs}" ]]; then
    echo "missing source file: ${source_abs}" >&2
    exit 1
  fi

  {
    printf '%s\n' "---"
    printf 'description: "%s"\n' "${description}"
    printf 'argument-hint: "%s"\n' "${arg_hint}"
    printf '%s\n' "---"
    printf '\n'
    printf '<!-- generated from %s -->\n' "${source_rel}"
    printf '<!-- run codex/scripts/install_claude_commands_as_prompts.sh to refresh -->\n'
    printf '\n'
    cat "${source_abs}"
    printf '\n'
  } > "${prompt_file}"

  echo "installed: ${prompt_file}"
done

echo
echo "Done. Available prompt commands:"
for prompt_id in "${PROMPT_IDS[@]}"; do
  echo "  /prompts:${prompt_id}"
done
