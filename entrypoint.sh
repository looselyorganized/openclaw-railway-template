#!/bin/bash
set -euo pipefail

OC_HOME="${OC_HOME:-$HOME/.openclaw}"

# --- First-boot config seeding ---
if [ ! -f "$OC_HOME/openclaw.json" ]; then
  echo "First boot detected — seeding default config..."
  mkdir -p "$OC_HOME"
  cp /app/openclaw.json.default "$OC_HOME/openclaw.json"
fi

# --- Inject environment variables into config ---
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] || [ -n "${TELEGRAM_ALLOW_FROM:-}" ] || [ -n "${TELEGRAM_DM_POLICY:-}" ]; then
  echo "Injecting Telegram config from environment..."
  node -e "
    const fs = require('fs');
    const configPath = '$OC_HOME/openclaw.json';
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    config.channels = config.channels || {};
    config.channels.telegram = config.channels.telegram || {};

    if (process.env.TELEGRAM_BOT_TOKEN) {
      config.channels.telegram.botToken = process.env.TELEGRAM_BOT_TOKEN;
    }

    if (process.env.TELEGRAM_DM_POLICY) {
      config.channels.telegram.dmPolicy = process.env.TELEGRAM_DM_POLICY;
    }

    if (process.env.TELEGRAM_ALLOW_FROM) {
      // Comma-separated list of Telegram user IDs
      config.channels.telegram.allowFrom = process.env.TELEGRAM_ALLOW_FROM
        .split(',')
        .map(id => id.trim())
        .filter(Boolean)
        .map(Number);
    }

    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  "
fi

# --- Validate config ---
echo "Running openclaw doctor..."
openclaw doctor --fix --yes

# --- Start gateway ---
echo "Starting OpenClaw gateway..."
exec openclaw gateway
