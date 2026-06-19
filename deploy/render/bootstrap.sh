#!/usr/bin/env sh
set -eu

BOOTSTRAP_MARKER="x_openchamber_bootstrap_managed"
HOME="${HOME:-/home/openchamber}"
OPENCHAMBER_DATA_ROOT="${OPENCHAMBER_DATA_ROOT:-${HOME}/data}"
OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
WORKSPACE_INDEX="${OPENCHAMBER_WORKSPACE_INDEX:-01}"
WORKSPACE_NAME="${OPENCHAMBER_WORKSPACE_NAME:-workspace-${WORKSPACE_INDEX}}"
WORKSPACE_DIR="${OPENCHAMBER_WORKSPACE_DIR:-${HOME}/workspaces/${WORKSPACE_NAME}}"
OPENCODE_ZED_BASE_URL="${OPENCODE_ZED_BASE_URL:-https://api.zed.md/v1}"
OPENCODE_ZED_PROVIDER_ID="${OPENCODE_ZED_PROVIDER_ID:-zed}"
OPENCODE_ZED_MODEL_ID="${OPENCODE_ZED_MODEL_ID:-deepseek}"
OPENCODE_DEFAULT_MODEL="${OPENCODE_DEFAULT_MODEL:-${OPENCODE_ZED_PROVIDER_ID}/${OPENCODE_ZED_MODEL_ID}}"
OPENCODE_SKILLS_DIR="${OPENCODE_CONFIG_DIR}/skills"
UPSTREAM_SKILL_CACHE="${OPENCHAMBER_DATA_ROOT}/upstream-skills"

export HOME OPENCHAMBER_DATA_ROOT OPENCODE_CONFIG_DIR
export OPENCHAMBER_WORKSPACE_DIR="${WORKSPACE_DIR}"
export OPENCHAMBER_OPENCODE_CWD="${OPENCHAMBER_OPENCODE_CWD:-${WORKSPACE_DIR}}"

log() {
  printf '%s\n' "[bootstrap] $*"
}

warn() {
  printf '%s\n' "[bootstrap] warning: $*" >&2
}

ensure_dir() {
  mkdir -p "$1"
}

link_or_migrate_dir() {
  target="$1"
  link="$2"

  ensure_dir "$target"
  ensure_dir "$(dirname "$link")"

  if [ -L "$link" ]; then
    return 0
  fi

  if [ -e "$link" ]; then
    if [ -d "$link" ]; then
      cp -a "$link"/. "$target"/ 2>/dev/null || warn "could not copy existing ${link} into ${target}"
    fi
    backup="${link}.bootstrap-backup.$(date +%s)"
    mv "$link" "$backup" 2>/dev/null || {
      warn "could not move existing ${link}; leaving it in place"
      return 0
    }
  fi

  ln -s "$target" "$link"
}

install_managed_file() {
  target="$1"
  marker="$2"
  temp_file="$(mktemp)"
  cat > "$temp_file"

  ensure_dir "$(dirname "$target")"
  if [ ! -f "$target" ] || grep -q "$marker" "$target" 2>/dev/null; then
    cp "$temp_file" "$target"
  else
    warn "not overwriting user-managed file ${target}"
  fi

  rm -f "$temp_file"
}

ensure_persistent_layout() {
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/config/openchamber"
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/config/opencode"
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/local/share/opencode"
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/local/state/opencode"
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/cache/opencode"
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/ssh"
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/workspaces"
  ensure_dir "${OPENCHAMBER_DATA_ROOT}/npm-cache"
  ensure_dir "${UPSTREAM_SKILL_CACHE}"

  link_or_migrate_dir "${OPENCHAMBER_DATA_ROOT}/config/openchamber" "${HOME}/.config/openchamber"
  link_or_migrate_dir "${OPENCHAMBER_DATA_ROOT}/config/opencode" "${HOME}/.config/opencode"
  link_or_migrate_dir "${OPENCHAMBER_DATA_ROOT}/local/share/opencode" "${HOME}/.local/share/opencode"
  link_or_migrate_dir "${OPENCHAMBER_DATA_ROOT}/local/state/opencode" "${HOME}/.local/state/opencode"
  link_or_migrate_dir "${OPENCHAMBER_DATA_ROOT}/cache/opencode" "${HOME}/.cache/opencode"
  link_or_migrate_dir "${OPENCHAMBER_DATA_ROOT}/ssh" "${HOME}/.ssh"
  link_or_migrate_dir "${OPENCHAMBER_DATA_ROOT}/workspaces" "${HOME}/workspaces"
}

write_opencode_config() {
  config_path="${OPENCODE_CONFIG_DIR}/opencode.json"
  managed_marker="${OPENCODE_CONFIG_DIR}/.openchamber-managed-opencode-config"
  temp_file="$(mktemp)"
  cat > "$temp_file" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${OPENCODE_DEFAULT_MODEL}",
  "small_model": "${OPENCODE_DEFAULT_MODEL}",
  "provider": {
    "${OPENCODE_ZED_PROVIDER_ID}": {
      "name": "Zed API",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "${OPENCODE_ZED_BASE_URL}",
        "apiKey": "{env:ZED_API_KEY}"
      },
      "models": {
        "${OPENCODE_ZED_MODEL_ID}": {
          "name": "DeepSeek"
        }
      }
    }
  },
  "mcp": {
    "firecrawl": {
      "type": "local",
      "command": [
        "/home/openchamber/deploy/render/bin/firecrawl-mcp-wrapper.sh"
      ],
      "enabled": true
    },
    "exa": {
      "type": "remote",
      "url": "https://mcp.exa.ai/mcp",
      "headers": {
        "x-api-key": "{env:EXA_API_KEY}"
      },
      "enabled": true
    }
  },
  "skills": {
    "paths": [
      "~/.config/opencode/skills",
      ".opencode/skills"
    ]
  }
}
EOF

  ensure_dir "$(dirname "$config_path")"
  if [ ! -f "$config_path" ] || [ -f "$managed_marker" ] || grep -q "$BOOTSTRAP_MARKER" "$config_path" 2>/dev/null; then
    cp "$temp_file" "$config_path"
    printf '%s\n' "$BOOTSTRAP_MARKER" > "$managed_marker"
  else
    warn "not overwriting user-managed file ${config_path}"
  fi

  rm -f "$temp_file"

  config_alias="${OPENCODE_CONFIG_DIR}/config.json"
  if [ ! -e "$config_alias" ]; then
    ln -s "$config_path" "$config_alias"
  fi
}

write_global_agents() {
  install_managed_file "${OPENCODE_CONFIG_DIR}/AGENTS.md" "$BOOTSTRAP_MARKER" <<'EOF'
<!-- x_openchamber_bootstrap_managed -->
# OpenChamber Runtime Contract

Отвечай пользователю по-русски, если он не попросил другой язык. Команды, пути, API, имена пакетов, ошибки и логи оставляй на английском.

Default runtime:
- UI: OpenChamber web runtime.
- Agent engine: OpenCode server inside this container.
- Default provider: `zed/deepseek`.
- Base URL: `https://api.zed.md/v1`.
- Search MCP: `firecrawl` and `exa`.

Secrets policy:
- Never print API keys, cookies, tokens, private keys, or `.env` contents.
- Use environment variables: `ZED_API_KEY`, `FIRECRAWL_API_KEY`, `EXA_API_KEY`.
- If a key is missing, report only the missing variable name.

Workspace policy:
- Treat the current workspace as the canonical project root.
- Prefer existing repo instructions and local `AGENTS.md` files.
- Verify claims with commands or durable evidence before saying work is done.
EOF
}

write_skill_adapter() {
  skill_name="$1"
  description="$2"
  source_url="$3"
  body="$4"
  skill_dir="${OPENCODE_SKILLS_DIR}/${skill_name}"

  install_managed_file "${skill_dir}/SKILL.md" "$BOOTSTRAP_MARKER" <<EOF
---
name: ${skill_name}
description: ${description}
source: ${source_url}
${BOOTSTRAP_MARKER}: true
---

${body}
EOF
}

write_skill_adapters() {
  ensure_dir "$OPENCODE_SKILLS_DIR"

  write_skill_adapter "superpowers" "Superpowers skill pack adapter for OpenCode runtimes." "https://github.com/obra/superpowers" "Use this when the user asks for Superpowers-style disciplined workflow. Prefer verification before completion, systematic debugging, and explicit stop conditions. If upstream Superpowers skills are installed, prefer the more specific upstream skill."

  write_skill_adapter "openagent" "OpenAgent / OpenAgentsControl adapter." "https://github.com/darrenhinde/OpenAgentsControl" "Use this when the user asks for OpenAgent-style agent control or OpenAgentsControl workflows. Keep execution local, reversible, and evidence-backed unless an external authority is required."

  write_skill_adapter "mattpocock-skills" "Matt Pocock skills pack adapter." "https://github.com/mattpocock/skills" "Use this as an entry point for Matt Pocock engineering/productivity skills. If upstream skills are installed, route to the specific skill such as grill-me, triage, diagnose, prototype, or zoom-out."

  write_skill_adapter "gpt-tasteskill" "GPT taste skill adapter." "https://github.com/Leonxlnx/taste-skill" "Use this for taste, visual judgment, and critique tasks. Preserve product intent, identify weak visual decisions, and propose concrete improvements."

  write_skill_adapter "grill-me" "Grill-me critique adapter." "https://github.com/mattpocock/skills" "Use this when the user asks to be grilled, challenged, or forced to tighten assumptions. Ask pointed questions only when the answer materially changes the result."

  write_skill_adapter "grill-with-docs" "Documentation-grounded grill adapter." "https://github.com/mattpocock/skills" "Use this when critique must be grounded in source docs or repo evidence. Do not rely on memory when current docs are available."

  write_skill_adapter "open-dynamic-workflows" "Open Dynamic Workflows adapter." "local-openchamber-bootstrap" "Use this for dynamic workflow routing where the user wants an explicit, reusable workflow. Keep workflow state visible and verify before transitioning states."

  write_skill_adapter "acpx-agent-delegation" "ACP x agent delegation adapter." "local-openchamber-bootstrap" "Use this for bounded subagent/delegation work. Delegate only independent slices, define ownership, integrate results, and own final verification."

  write_skill_adapter "understand-anything" "Understand Anything adapter." "https://github.com/Lum1104/Understand-Anything" "Use this to map unfamiliar codebases or topics. Start from structure, identify domains and dependency edges, then summarize in the user's language."

  write_skill_adapter "graphify" "Graphify adapter." "https://github.com/safishamsi/graphify" "Use this when the user asks to turn relationships into graphs. Prefer Mermaid or structured graph output with clear nodes, edges, and labels."

  write_skill_adapter "activegraph" "ActiveGraph adapter." "https://github.com/yoheinakajima/activegraph" "Use this when the user asks for active knowledge graph workflows. Keep graph updates explicit: source, node, edge, confidence, and next query."
}

copy_upstream_skill_dirs() {
  repo_dir="$1"

  find -L "$repo_dir" -path '*/.git' -prune -o -name SKILL.md -type f -print | while IFS= read -r skill_file; do
    parent_dir="$(dirname "$skill_file")"
    if [ -d "${parent_dir}/.git" ]; then
      continue
    fi

    raw_name="$(basename "$parent_dir")"
    skill_name="$(printf '%s' "$raw_name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-' | sed 's/^-//;s/-$//')"
    if [ -z "$skill_name" ]; then
      continue
    fi

    dest="${OPENCODE_SKILLS_DIR}/${skill_name}"
    if [ -f "${dest}/SKILL.md" ] && ! grep -q "$BOOTSTRAP_MARKER" "${dest}/SKILL.md" 2>/dev/null; then
      continue
    fi

    rm -rf "$dest"
    ensure_dir "$dest"
    cp -R "${parent_dir}/." "$dest"/
    rm -rf "${dest}/.git" "${dest}/node_modules"
  done
}

install_upstream_repo_skills() {
  repo_url="$1"
  slug="$2"
  repo_dir="${UPSTREAM_SKILL_CACHE}/${slug}"

  if ! command -v git >/dev/null 2>&1; then
    warn "git is unavailable; skipping ${repo_url}"
    return 0
  fi

  if [ -d "${repo_dir}/.git" ]; then
    if [ "${OPENCHAMBER_REFRESH_UPSTREAM_SKILLS:-false}" = "true" ]; then
      git -C "$repo_dir" pull --ff-only >/dev/null 2>&1 || warn "could not refresh ${repo_url}"
    fi
  else
    rm -rf "$repo_dir"
    if ! git clone --depth 1 "$repo_url" "$repo_dir" >/dev/null 2>&1; then
      warn "could not clone ${repo_url}; keeping adapter skill"
      return 0
    fi
  fi

  copy_upstream_skill_dirs "$repo_dir"
}

install_upstream_skills() {
  if [ "${OPENCHAMBER_INSTALL_UPSTREAM_SKILLS:-true}" != "true" ]; then
    return 0
  fi

  install_upstream_repo_skills "https://github.com/obra/superpowers.git" "obra-superpowers"
  install_upstream_repo_skills "https://github.com/mattpocock/skills.git" "mattpocock-skills"
  install_upstream_repo_skills "https://github.com/Leonxlnx/taste-skill.git" "leonxlnx-taste-skill"
  install_upstream_repo_skills "https://github.com/Lum1104/Understand-Anything.git" "lum1104-understand-anything"
  install_upstream_repo_skills "https://github.com/safishamsi/graphify.git" "safishamsi-graphify"
  install_upstream_repo_skills "https://github.com/yoheinakajima/activegraph.git" "yoheinakajima-activegraph"
  install_upstream_repo_skills "https://github.com/darrenhinde/OpenAgentsControl.git" "darrenhinde-openagentscontrol"
}

seed_workspace() {
  ensure_dir "$WORKSPACE_DIR"
  ensure_dir "${WORKSPACE_DIR}/.opencode"

  install_managed_file "${WORKSPACE_DIR}/AGENTS.md" "$BOOTSTRAP_MARKER" <<EOF
<!-- ${BOOTSTRAP_MARKER} -->
# ${WORKSPACE_NAME}

Это русскоязычный OpenChamber workspace ${WORKSPACE_INDEX}.

Default runtime:
- Provider: \`${OPENCODE_DEFAULT_MODEL}\`
- Base URL: \`${OPENCODE_ZED_BASE_URL}\`
- OpenCode config: \`${OPENCODE_CONFIG_DIR}/opencode.json\`
- User skills: \`${OPENCODE_SKILLS_DIR}\`
- Search MCP: \`firecrawl\`, \`exa\`

Правила:
- Общайся с пользователем по-русски, если он явно не просит другой язык.
- Не печатай секреты. Если ключа нет, называй только env var.
- Проверяй результат перед тем, как писать "готово".
EOF

  install_managed_file "${WORKSPACE_DIR}/README.md" "$BOOTSTRAP_MARKER" <<EOF
<!-- ${BOOTSTRAP_MARKER} -->
# ${WORKSPACE_NAME}

Workspace создан bootstrap-скриптом OpenChamber для Render runtime ${WORKSPACE_INDEX}.

Сюда можно класть проектные файлы, заметки и локальные инструкции. Runtime уже видит OpenCode provider \`${OPENCODE_DEFAULT_MODEL}\`, Firecrawl MCP, Exa MCP и базовый набор skills.
EOF

  project_config="${WORKSPACE_DIR}/.opencode/opencode.json"
  install_managed_file "$project_config" "$BOOTSTRAP_MARKER" <<EOF
{
  "${BOOTSTRAP_MARKER}": true,
  "model": "${OPENCODE_DEFAULT_MODEL}",
  "small_model": "${OPENCODE_DEFAULT_MODEL}",
  "skills": {
    "paths": [
      "${OPENCODE_SKILLS_DIR}"
    ]
  }
}
EOF

  if [ ! -e "${WORKSPACE_DIR}/.opencode/skills" ]; then
    ln -s "$OPENCODE_SKILLS_DIR" "${WORKSPACE_DIR}/.opencode/skills"
  fi
}

ensure_persistent_layout
write_opencode_config
write_global_agents
write_skill_adapters
install_upstream_skills
seed_workspace

log "workspace ${WORKSPACE_NAME} ready at ${WORKSPACE_DIR}"
