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

    // Allow Control UI from Railway public domain
    if (process.env.RAILWAY_PUBLIC_DOMAIN) {
      c.gateway = c.gateway || {};
      c.gateway.controlUi = c.gateway.controlUi || {};
      c.gateway.controlUi.allowedOrigins = [
        'https://' + process.env.RAILWAY_PUBLIC_DOMAIN
      ];
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
echo "Starting OpenClaw gateway..."
exec openclaw gateway
