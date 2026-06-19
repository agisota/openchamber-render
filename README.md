# Rox Space

Rox Space is a Render-hosted AI workspace runtime built around an embedded OpenCode server, Zed-compatible model provider defaults, and managed MCP search connectors.

This branch is the deployment bundle for ten isolated Render runtimes:

- `rox-space-01` through `rox-space-10`
- one persistent Render disk per runtime
- one Russian-first workspace per runtime
- default model: `zed/deepseek`
- base URL: `https://api.zed.md/v1`
- MCP: `firecrawl` and `exa`
- local Rox Space skill adapters seeded into OpenCode
- browser UI password gate disabled for this deployment

The runtime keeps existing internal package names and environment variable names for compatibility with the application code. User-facing names, workspace bootstrap files, Render blueprint names, browser titles, PWA metadata, and diagnostics are branded as Rox Space.

## Render

The Render blueprint is in `render.yaml`. Deployment-specific bootstrap files are in `deploy/render/`.

Useful local checks before pushing:

```bash
sh -n scripts/docker-entrypoint.sh
sh -n deploy/render/bootstrap.sh
bun test packages/web/server/lib/opencode/static-routes-runtime.test.js
bun run type-check
bun run lint
```

## Runtime

Each service starts the web server in foreground mode and persists runtime state under `/home/openchamber/data`. The `/home/openchamber` path is intentionally kept for compatibility with the container image.

Secrets are supplied through Render environment variables and must not be committed:

- `ZED_API_KEY`
- `FIRECRAWL_API_KEY`
- `EXA_API_KEY`
