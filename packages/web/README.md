# Rox Space Web Runtime

Rox Space web runtime serves the browser UI, API routes, terminal bridge, file access, project actions, and managed agent-session features used by the deployed Rox Space services.

## Development

Run commands from the repository root unless a package-specific command is needed.

```bash
bun install
bun run build:web
bun run type-check:web
bun run lint:web
```

## Runtime Notes

- The packaged server can run as a foreground service for platform process managers.
- OpenCode remains the managed agent backend and can be started locally or connected through an external `OPENCODE_HOST`.
- Public deployments should explicitly configure UI authentication policy, provider credentials, MCP connectors, and persistent storage.

## Render Deployment

The Rox Space Render bundle lives in `deploy/render/` and `render.yaml`. It preconfigures ten isolated workspaces, default provider settings, Firecrawl/Exa MCP connectors, and Russian-first workspace instructions.
