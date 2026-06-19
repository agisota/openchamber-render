# Rox Space VS Code Extension

Rox Space for VS Code embeds the shared Rox Space chat UI inside the editor and connects it to a local or remote OpenCode API server.

## What You Get

- Chat beside your code in a responsive editor panel.
- Agent Manager for parallel multi-model runs.
- Right-click actions for adding context, explaining selections, and improving code.
- Click-to-open file paths and focused diff views.
- Session editor panels that stay open beside source files.
- Theme-aware UI for light, dark, and high-contrast modes.

## Commands

| Command | Description |
|---------|-------------|
| `Rox Space: Focus Chat` | Focus the chat panel |
| `Rox Space: New Session` | Start a new chat session |
| `Rox Space: Open Sidebar` | Open the Rox Space sidebar |
| `Rox Space: Open Agent Manager` | Launch parallel multi-model runs |
| `Rox Space: Open Session in Editor` | Open current or new session in an editor tab |
| `Rox Space: Settings` | Open extension settings |
| `Rox Space: Restart API Connection` | Restart the OpenCode API process |
| `Rox Space: Show OpenCode Status` | Debug info for development or bug reports |

## Development

```bash
bun install
bun run vscode:dev
bun run vscode:build
```

Optional overrides:

- `OPENCHAMBER_VSCODE_BIN=cursor bun run vscode:dev`
- `OPENCHAMBER_VSCODE_DEV_WORKSPACE=/path/to/workspace bun run vscode:dev`
- `bun run vscode:dev /path/to/workspace`

To package manually:

```bash
bun run --cwd packages/vscode build
cd packages/vscode && bunx vsce package --no-dependencies
```
