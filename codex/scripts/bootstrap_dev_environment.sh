#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PRE_COMMIT_BIN=""
CODEX_HOME_DIR="${CODEX_HOME:-${REPO_ROOT}/.codex-home}"

find_pre_commit() {
  if command -v pre-commit >/dev/null 2>&1; then
    PRE_COMMIT_BIN="$(command -v pre-commit)"
    return 0
  fi
  if [[ -x "${HOME}/.local/bin/pre-commit" ]]; then
    PRE_COMMIT_BIN="${HOME}/.local/bin/pre-commit"
    return 0
  fi
  return 1
}

install_pre_commit_if_missing() {
  if find_pre_commit; then
    echo "pre-commit found: ${PRE_COMMIT_BIN}"
    return 0
  fi

  echo "pre-commit not found. Installing with pip user site..."
  python3 -m pip install --user pre-commit
  if ! find_pre_commit; then
    echo "failed to locate pre-commit after install" >&2
    exit 1
  fi
  echo "pre-commit installed: ${PRE_COMMIT_BIN}"
}

is_git_repository() {
  git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

install_git_hooks() {
  local install_output=""

  if ! install_output="$("${PRE_COMMIT_BIN}" install 2>&1)"; then
    echo "warning: pre-commit install failed."
    echo "detail: $(printf '%s\n' "${install_output}" | head -n 1)"
    return 1
  fi

  if ! install_output="$("${PRE_COMMIT_BIN}" install --hook-type pre-push 2>&1)"; then
    echo "warning: pre-commit pre-push hook install failed."
    echo "detail: $(printf '%s\n' "${install_output}" | head -n 1)"
    return 1
  fi

  return 0
}

main() {
  cd "${REPO_ROOT}"

  install_pre_commit_if_missing

  export CODEX_HOME="${CODEX_HOME_DIR}"
  mkdir -p "${CODEX_HOME}/prompts"
  echo "using CODEX_HOME: ${CODEX_HOME}"

  echo "syncing .claude/commands compatibility prompts..."
  bash codex/scripts/install_claude_commands_as_prompts.sh

  if is_git_repository; then
    echo "git repository detected. installing git hooks..."
    if install_git_hooks; then
      echo "running full pre-commit checks (skip protected-branch commit guard)..."
      SKIP=no-commit-to-branch "${PRE_COMMIT_BIN}" run --all-files
    else
      echo "warning: failed to install git hooks (environment may block writing .git/hooks)."
      echo "skipping pre-commit run --all-files in bootstrap."
      echo "run pre-commit commands manually in a writable git environment."
    fi
  else
    echo "git repository not detected at ${REPO_ROOT}"
    echo "skipping git hook install and pre-commit run --all-files"
  fi

  echo
  echo "Bootstrap completed."
  echo "Prompt files location: ${CODEX_HOME}/prompts"
  echo "Try these prompt commands in Codex:"
  echo "  /prompts:req-phase1"
  echo "  /prompts:req-phase2"
  echo "  /prompts:req-phase3"
}

main "$@"
