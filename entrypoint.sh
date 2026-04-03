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

    // Default model
    if (process.env.OPENCLAW_MODEL) {
      c.agents = c.agents || {};
      c.agents.defaults = c.agents.defaults || {};
      c.agents.defaults.model = process.env.OPENCLAW_MODEL;
    }

    // Gateway auth token
    if (process.env.OPENCLAW_GATEWAY_TOKEN) {
      c.gateway = c.gateway || {};
      c.gateway.auth = c.gateway.auth || {};
      c.gateway.auth.mode = 'token';
      c.gateway.auth.token = process.env.OPENCLAW_GATEWAY_TOKEN;
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
