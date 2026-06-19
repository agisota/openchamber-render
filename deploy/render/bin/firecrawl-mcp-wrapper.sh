#!/usr/bin/env sh
set -eu

if [ -z "${FIRECRAWL_API_KEY:-}" ]; then
  echo "[mcp-firecrawl] FIRECRAWL_API_KEY is not set" >&2
  exit 1
fi

exec npx -y firecrawl-mcp
