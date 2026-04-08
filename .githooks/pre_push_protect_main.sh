#!/usr/bin/env bash
set -euo pipefail

while read -r local_ref local_sha remote_ref remote_sha; do
  case "${remote_ref}" in
    refs/heads/main|refs/heads/master)
      echo "[blocked] push to protected branch '${remote_ref#refs/heads/}' is not allowed by local hook." >&2
      echo "Push to a feature branch and open a PR instead." >&2
      exit 1
      ;;
  esac
done

exit 0
