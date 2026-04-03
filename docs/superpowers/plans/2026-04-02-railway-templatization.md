# Railway Templatization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make railclaw a proper Railway template — no hardcoded values, all config injectable at deploy time, Railway-native healthcheck and restart behavior.

**Architecture:** The OpenClaw gateway reads `openclaw.json` for config with native `${VAR}` env var substitution. The entrypoint bridges Railway's `PORT` to `OPENCLAW_GATEWAY_PORT`, injects user-configurable values (Telegram allowlist, model, DM policy) into the config JSON, then starts the gateway. Railway's `railway.toml` handles healthcheck (`/healthz` — native to OpenClaw), restart policy, and builder selection.

**Tech Stack:** Docker, Bash (entrypoint), OpenClaw gateway, Railway config-as-code (TOML)

**Key Reference — OpenClaw env var precedence:** `--flag` > env var > config file > hardcoded default. Gateway uses `OPENCLAW_GATEWAY_PORT` (not `PORT`). Bind mode `"lan"` = `0.0.0.0`. Config supports `${UPPERCASE_VAR}` substitution — missing/empty vars throw at load time.

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `railway.toml` | Create | Railway build/deploy config: Dockerfile builder, healthcheck, restart policy |
| `openclaw.json` | Modify | Generic defaults — remove hardcoded Telegram ID, use `${VAR}` substitution for gateway token |
| `entrypoint.sh` | Rewrite | Bridge `PORT` → `OPENCLAW_GATEWAY_PORT`, inject configurable env vars into config JSON |
| `Dockerfile` | Modify | Remove hardcoded `EXPOSE`, add env var defaults |
| `.env.example` | Rewrite | Document all variables with descriptions |
| `README.md` | Create | Deploy button, variable reference, what this template does |

---

### Task 1: Add `railway.toml`

**Files:**
- Create: `railway.toml`

- [ ] **Step 1: Create `railway.toml`**

```toml
[build]
builder = "DOCKERFILE"

[deploy]
healthcheckPath = "/healthz"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 5
```

Notes:
- `/healthz` is OpenClaw's native liveness endpoint (no auth required, served on gateway port)
- `DOCKERFILE` builder since we have a Dockerfile
- `ON_FAILURE` with 5 retries is Railway best practice for persistent services

- [ ] **Step 2: Commit**

```bash
git add railway.toml
git commit -m "feat: add railway.toml with healthcheck and restart policy"
```

---

### Task 2: Clean up `openclaw.json` defaults

**Files:**
- Modify: `openclaw.json`

- [ ] **Step 1: Rewrite `openclaw.json` to generic defaults**

Replace the entire file with:

```json
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "controlUi": { "enabled": true },
    "auth": { "mode": "token", "token": "${OPENCLAW_GATEWAY_TOKEN}" }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": []
    }
  },
  "agents": {
    "defaults": {
      "model": "anthropic/claude-sonnet-4-6"
    }
  }
}
```

Changes from original:
- `auth.token` uses `${OPENCLAW_GATEWAY_TOKEN}` env var substitution (OpenClaw native feature)
- `allowFrom` is empty array (no hardcoded Telegram ID `8638104723`)
- All else stays — `bind: "lan"` is correct (maps to `0.0.0.0`), model is a sensible default

- [ ] **Step 2: Commit**

```bash
git add openclaw.json
git commit -m "fix: remove hardcoded telegram ID, use env var substitution for gateway token"
```

---

### Task 3: Rewrite `entrypoint.sh`

**Files:**
- Modify: `entrypoint.sh`

- [ ] **Step 1: Rewrite entrypoint to handle all env var injection**

Replace the entire file with:

```bash
#!/bin/bash
set -euo pipefail

OC_HOME="${OC_HOME:-$HOME/.openclaw}"
CONFIG="$OC_HOME/openclaw.json"

# --- First-boot config seeding ---
if [ ! -f "$CONFIG" ]; then
  echo "First boot — seeding default config..."
  mkdir -p "$OC_HOME"
  cp /app/openclaw.json.default "$CONFIG"
fi

# --- Bridge Railway PORT to OpenClaw ---
if [ -n "${PORT:-}" ]; then
  export OPENCLAW_GATEWAY_PORT="$PORT"
  echo "Bridging Railway PORT=$PORT → OPENCLAW_GATEWAY_PORT"
fi

# --- Inject configurable values into config ---
inject_config() {
  local tmp="$CONFIG.tmp"
  node -e "
    const fs = require('fs');
    const c = JSON.parse(fs.readFileSync('$CONFIG', 'utf8'));

    // Telegram bot token
    if (process.env.TELEGRAM_BOT_TOKEN) {
      c.channels = c.channels || {};
      c.channels.telegram = c.channels.telegram || {};
      c.channels.telegram.botToken = process.env.TELEGRAM_BOT_TOKEN;
    }

    // Telegram allow list (comma-separated IDs)
    if (process.env.TELEGRAM_ALLOW_FROM) {
      c.channels = c.channels || {};
      c.channels.telegram = c.channels.telegram || {};
      c.channels.telegram.allowFrom = process.env.TELEGRAM_ALLOW_FROM
        .split(',')
        .map(id => parseInt(id.trim(), 10))
        .filter(id => !isNaN(id));
    }

    // Telegram DM policy
    if (process.env.TELEGRAM_DM_POLICY) {
      c.channels = c.channels || {};
      c.channels.telegram = c.channels.telegram || {};
      c.channels.telegram.dmPolicy = process.env.TELEGRAM_DM_POLICY;
    }

    // Default model
    if (process.env.OPENCLAW_MODEL) {
      c.agents = c.agents || {};
      c.agents.defaults = c.agents.defaults || {};
      c.agents.defaults.model = process.env.OPENCLAW_MODEL;
    }

    // Control UI toggle
    if (process.env.CONTROL_UI_ENABLED !== undefined) {
      c.gateway = c.gateway || {};
      c.gateway.controlUi = c.gateway.controlUi || {};
      c.gateway.controlUi.enabled = process.env.CONTROL_UI_ENABLED !== 'false';
    }

    fs.writeFileSync('$tmp', JSON.stringify(c, null, 2));
  "
  mv "$tmp" "$CONFIG"
  echo "Config updated with environment overrides"
}

inject_config

# --- Validate config ---
echo "Running openclaw doctor..."
openclaw doctor --fix --yes

# --- Start gateway ---
echo "Starting OpenClaw gateway on port ${OPENCLAW_GATEWAY_PORT:-18789}..."
exec openclaw gateway
```

Key changes from original:
- Bridges `PORT` → `OPENCLAW_GATEWAY_PORT` (Railway injects `PORT`, OpenClaw reads `OPENCLAW_GATEWAY_PORT`)
- Single `inject_config` function handles all env vars in one `node -e` pass
- Writes to tmp file then `mv` — atomic replacement, no corruption on error
- New injectable vars: `TELEGRAM_ALLOW_FROM`, `TELEGRAM_DM_POLICY`, `OPENCLAW_MODEL`, `CONTROL_UI_ENABLED`
- Logs the port at startup for debugging

- [ ] **Step 2: Commit**

```bash
git add entrypoint.sh
git commit -m "feat: rewrite entrypoint — bridge PORT, inject all configurable env vars"
```

---

### Task 4: Update `Dockerfile`

**Files:**
- Modify: `Dockerfile`

- [ ] **Step 1: Update Dockerfile**

Replace the entire file with:

```dockerfile
FROM ghcr.io/openclaw/openclaw:latest

COPY openclaw.json /app/openclaw.json.default
COPY --chmod=755 entrypoint.sh /app/entrypoint.sh

ENV NODE_ENV=production

CMD ["/app/entrypoint.sh"]
```

Changes:
- Removed `EXPOSE 18789` — Railway assigns the port dynamically via `$PORT`; hardcoded EXPOSE is misleading and unnecessary

- [ ] **Step 2: Commit**

```bash
git add Dockerfile
git commit -m "fix: remove hardcoded EXPOSE, Railway assigns PORT dynamically"
```

---

### Task 5: Rewrite `.env.example`

**Files:**
- Modify: `.env.example`

- [ ] **Step 1: Rewrite `.env.example` with all variables and descriptions**

```bash
# === Required ===

# Anthropic API key for Claude models
ANTHROPIC_API_KEY=

# Gateway auth token — secures the gateway API
# On Railway, use ${{secret(32)}} template function to auto-generate
OPENCLAW_GATEWAY_TOKEN=

# === Telegram Channel ===

# Bot token from @BotFather
TELEGRAM_BOT_TOKEN=

# Comma-separated Telegram user IDs allowed to DM the bot
# Find your ID: message @userinfobot on Telegram
TELEGRAM_ALLOW_FROM=

# DM policy: "allowlist" (default) or "open"
# TELEGRAM_DM_POLICY=allowlist

# === Optional ===

# Override default agent model (default: anthropic/claude-sonnet-4-6)
# OPENCLAW_MODEL=anthropic/claude-sonnet-4-6

# OpenAI API key (if using OpenAI models)
# OPENAI_API_KEY=

# Brave Search API key (if using web search tool)
# BRAVE_SEARCH_API_KEY=

# Toggle Control UI (default: true)
# CONTROL_UI_ENABLED=true
```

- [ ] **Step 2: Commit**

```bash
git add .env.example
git commit -m "docs: rewrite .env.example with all configurable variables"
```

---

### Task 6: Add `README.md`

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create README**

```markdown
# OpenClaw Railway Template

One-click deploy of [OpenClaw](https://openclaw.dev) on [Railway](https://railway.com) — a pre-configured gateway with Telegram channel support.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/TODO)

## What You Get

- OpenClaw gateway with token auth
- Telegram bot channel (allowlist DM policy)
- Health checks (`/healthz`, `/readyz`)
- Auto-restart on failure (5 retries)

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key for Claude models |
| `OPENCLAW_GATEWAY_TOKEN` | Gateway auth token — use `${{secret(32)}}` in Railway template |
| `TELEGRAM_BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_ALLOW_FROM` | Comma-separated Telegram user IDs (find yours via [@userinfobot](https://t.me/userinfobot)) |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_MODEL` | `anthropic/claude-sonnet-4-6` | Default agent model |
| `TELEGRAM_DM_POLICY` | `allowlist` | `allowlist` or `open` |
| `CONTROL_UI_ENABLED` | `true` | Toggle the gateway Control UI |
| `OPENAI_API_KEY` | — | Required only if using OpenAI models |
| `BRAVE_SEARCH_API_KEY` | — | Required only if using web search tool |

## How It Works

1. Railway builds the Docker image from `ghcr.io/openclaw/openclaw:latest`
2. On first boot, the entrypoint seeds the default config
3. Environment variables are injected into the config at startup
4. Railway's `PORT` is bridged to `OPENCLAW_GATEWAY_PORT`
5. `openclaw doctor --fix --yes` validates the config
6. The gateway starts and Railway healthchecks `/healthz`

## Local Development

```bash
cp .env.example .env
# Fill in your values
docker build -t openclaw-railway .
docker run --env-file .env -p 18789:18789 openclaw-railway
```
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with deploy button, variable reference, and architecture"
```

---

### Task 7: Verify (manual)

- [ ] **Step 1: Review all files for consistency**

```bash
cat railway.toml
cat openclaw.json
cat entrypoint.sh
cat Dockerfile
cat .env.example
cat README.md
```

Verify:
- No hardcoded secrets, user IDs, or non-default ports
- All env vars in `.env.example` match what `entrypoint.sh` handles
- `railway.toml` healthcheck path matches OpenClaw's native `/healthz`
- Dockerfile has no `EXPOSE`
- README variable table matches `.env.example`

- [ ] **Step 2: Final commit if any fixups needed**
