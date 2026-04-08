#!/usr/bin/env bash
set -euo pipefail

echo "Running default verification flow..."
pnpm lint
pnpm test
