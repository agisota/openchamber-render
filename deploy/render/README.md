# Render Rox Space Deployment

## Current State

This repository builds one Rox Space runtime image. The image already installs `opencode-ai`; this deployment layer adds persistent runtime bootstrap for Render, OpenCode provider defaults, MCP search connectors, Russian workspace instructions, and the requested skill seed set.

Render CLI is installed locally, but the workstation is not authenticated to Render yet. Secrets and custom domains are intentionally not committed.

## Target State

Ten Render web services run the same Rox Space image:

- `rox-space-01` through `rox-space-10`
- one persistent disk per service mounted at `/home/openchamber/data`
- one default workspace per service: `rox-space-01` through `rox-space-10`
- OpenCode default model: `zed/cx/gpt-5.5-medium`
- OpenAI-compatible base URL: `https://api.zed.md/v1`
- MCP: `firecrawl` and `exa`
- Russian `AGENTS.md` and `README.md` in every seeded workspace
- UI password disabled for this controlled runtime deployment

## Gap / Transformation

Render disks must not mount over `/home/openchamber`, because that path contains the built app. The blueprint mounts disks at `/home/openchamber/data`, then `bootstrap.sh` symlinks Rox Space/OpenCode config, cache, SSH, and workspace paths into that persistent root.

OpenCode keys are supplied only as environment variables:

- `ZED_API_KEY`
- `FIRECRAWL_API_KEY`
- `EXA_API_KEY`

`render.yaml` marks secret values with `sync: false`, so Render stores them as secrets and they are not written to git.

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> LocalBundleReady
    LocalBundleReady --> BlueprintValid: render blueprints validate
    BlueprintValid --> RenderAuthBlocked: render login missing
    BlueprintValid --> BlueprintApplied: authenticated Render workspace
    BlueprintApplied --> SecretsBlocked: required env values missing
    SecretsBlocked --> ServicesBuilding: secrets added
    ServicesBuilding --> DomainsPending: health checks pass
    DomainsPending --> Ready: custom domains attached and DNS verified
    ServicesBuilding --> Failed: build, boot, or health failure
```

## Recommended Path

Use the 10-service Render Blueprint.

Rejected alternatives:

- One Render service with 10 folders: cheaper, but not 10 independent runtimes.
- One service plus project switching: simpler, but restarts/logs/secrets/storage are shared.
- Ten manual Render services: works once, but drift is likely.

The blueprint path costs more, but it matches the request for 10 identical runtimes and gives isolated logs, restarts, disks, and domain bindings.

## Apply

1. Push this repository to the GitHub repository Render should build from.
2. Authenticate the Render CLI:

```bash
render login
```

3. Validate the blueprint:

```bash
render blueprints validate ./render.yaml
```

4. Create or sync the Blueprint in Render from this repository.
5. Add the secret env vars in Render for every service or via a Render Environment Group if you prefer to centralize them.
6. Attach domains, for example:

```text
space1.spaceman.space -> rox-space-01
space2.spaceman.space -> rox-space-02
...
space10.spaceman.space -> rox-space-10
```

7. Verify each runtime:

```bash
curl -fsS https://space1.spaceman.space/health
curl -fsS https://space10.spaceman.space/health
```

## Skills

`bootstrap.sh` always creates OpenCode adapter skills for:

- `superpowers`
- `openagent`
- `mattpocock-skills`
- `gpt-tasteskill`
- `grill-me`
- `grill-with-docs`
- `open-dynamic-workflows`
- `acpx-agent-delegation`
- `understand-anything`
- `graphify`
- `activegraph`

The deployment uses local Rox Space adapter skills. It does not clone upstream skill repositories by default.

## Verification Proof

Local proof before Render auth:

- `sh -n scripts/docker-entrypoint.sh`
- `sh -n deploy/render/bootstrap.sh`
- bootstrap smoke test with a temporary home/data root
- `render blueprints validate ./render.yaml` after `render login`

Render proof after auth/secrets/domain:

- all 10 services build successfully
- `/health` returns success on each service
- UI opens without a session password gate; `OPENCHAMBER_ALLOW_UNAUTHENTICATED_LAN=true` is set intentionally for public Render access
- OpenCode starts in the expected `rox-space-NN`
- `~/.config/opencode/opencode.json` contains `zed/cx/gpt-5.5-medium`, Firecrawl MCP, and Exa MCP
