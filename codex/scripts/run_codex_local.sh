#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

export CODEX_HOME="${CODEX_HOME:-${REPO_ROOT}/.codex-home}"
mkdir -p "${CODEX_HOME}"

exec codex "$@"
