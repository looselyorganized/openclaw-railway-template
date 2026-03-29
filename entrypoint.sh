#!/bin/bash
set -euo pipefail

OC_HOME="${OC_HOME:-$HOME/.openclaw}"

# --- First-boot config seeding ---
if [ ! -f "$OC_HOME/openclaw.json" ]; then
  echo "First boot detected — seeding default config..."
  mkdir -p "$OC_HOME"
  cp /app/openclaw.json.default "$OC_HOME/openclaw.json"
fi

# --- Inject TELEGRAM_BOT_TOKEN into config ---
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  echo "Injecting TELEGRAM_BOT_TOKEN..."
  node -e "
    const fs = require('fs');
    const configPath = '$OC_HOME/openclaw.json';
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    config.channels = config.channels || {};
    config.channels.telegram = config.channels.telegram || {};
    config.channels.telegram.botToken = process.env.TELEGRAM_BOT_TOKEN;
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  "
fi

# --- Validate config ---
echo "Running openclaw doctor..."
openclaw doctor --fix --yes

# --- Start gateway ---
echo "Starting OpenClaw gateway..."
exec openclaw gateway
