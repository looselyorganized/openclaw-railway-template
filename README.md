# OpenClaw Railway Template

Deploy an OpenClaw AI agent gateway to Railway.

## What is OpenClaw?

OpenClaw is an AI agent gateway powered by Anthropic's Claude. This template gives you a production-ready deployment with:

- **Telegram bot integration** for chatting with your AI agent
- **Control UI** for managing agents and configuration
- **Token-based authentication** for secure API access
- **Web search** via Brave Search API (optional)
- **Semantic memory** via OpenAI embeddings (optional)

## Quick Start

### 1. Deploy to Railway

1. Fork this repository
2. Create a new project on [Railway](https://railway.app)
3. Select **Deploy from GitHub repo** and connect your fork
4. Add the required environment variables (see below)
5. Deploy

Railway will automatically detect the `Dockerfile` and build the service.

### 2. Set Environment Variables

In your Railway service settings, add the following variables:

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | Your Anthropic API key for Claude |
| `OPENCLAW_GATEWAY_TOKEN` | Yes | A secret token for authenticating with the gateway API |
| `TELEGRAM_BOT_TOKEN` | For Telegram | Telegram bot token from [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_ALLOW_FROM` | For Telegram | Comma-separated Telegram user IDs allowed to message the bot (e.g. `123456,789012`) |
| `TELEGRAM_DM_POLICY` | No | DM policy: `allowlist` (default) or `open` |
| `OPENAI_API_KEY` | No | OpenAI API key for semantic memory embeddings |
| `BRAVE_SEARCH_API_KEY` | No | Brave Search API key for web search capability |

Find your Telegram user ID by messaging [@userinfobot](https://t.me/userinfobot).

### 3. Configure Networking

Railway does not expose services publicly by default. To access your gateway:

1. Go to your service's **Settings** tab in Railway
2. Under **Networking**, click **Generate Domain** to get a public URL
3. Set the Railway **Port** variable to `18789`, or configure a custom domain

The OpenClaw gateway listens on port `18789`.

### 4. Access the Control UI

Visit your Railway-assigned domain to access the OpenClaw control UI. Authenticate using your `OPENCLAW_GATEWAY_TOKEN`.

## Configuration

The default configuration template lives in `openclaw.json`:

```json
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "controlUi": { "enabled": true },
    "auth": { "mode": "token" }
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

### Key settings

- **`agents.defaults.model`** — The default Claude model for agents.

All Telegram-specific settings (`botToken`, `allowFrom`, `dmPolicy`) are injected from environment variables at startup — you should not need to edit `openclaw.json` for per-instance configuration.

### Persistence warning

Railway containers are **ephemeral** — the filesystem is wiped on every redeploy. This means:

- Config is re-seeded from `openclaw.json` and env vars on **every deploy**.
- Any configuration changes made through the Control UI will be **lost on the next deploy**.
- To change base config, edit `openclaw.json` in this repo. For instance-specific values, use environment variables.

If you need persistent runtime config, attach a [Railway volume](https://docs.railway.com/guides/volumes) mounted at `/root/.openclaw`.

## Project Structure

```
.
├── Dockerfile          # Builds from the official OpenClaw image
├── entrypoint.sh       # Config seeding & Telegram token injection on startup
├── openclaw.json       # Default configuration template
└── .env.example        # Environment variable reference
```

## How It Works

1. The `Dockerfile` pulls the official `ghcr.io/openclaw/openclaw:latest` image
2. On startup, `entrypoint.sh` seeds the default config and injects Telegram settings from env vars
3. `openclaw doctor --fix --yes` validates and auto-fixes the configuration
4. The gateway starts and listens on port `18789`

The `OPENCLAW_GATEWAY_TOKEN` and API key variables are read directly by the OpenClaw runtime — they do not appear in `entrypoint.sh`.

## Local Development

```bash
# Copy the env template and fill in your keys
cp .env.example .env

# Build and run with Docker
docker build -t openclaw-gateway .
docker run --env-file .env -p 18789:18789 openclaw-gateway
```

Visit `http://localhost:18789` to access the control UI.

## Troubleshooting

| Problem | Likely cause |
|---|---|
| Gateway starts but Telegram bot doesn't respond | `TELEGRAM_BOT_TOKEN` is missing or invalid, or your Telegram user ID is not in `TELEGRAM_ALLOW_FROM` |
| 401 Unauthorized from the gateway API | `OPENCLAW_GATEWAY_TOKEN` is missing or doesn't match your request |
| Control UI unreachable after deploy | No public domain generated — see [Configure Networking](#3-configure-networking) |
| Config changes lost after redeploy | Expected — Railway containers are ephemeral. Edit `openclaw.json` in the repo or attach a volume |
| `openclaw doctor` fails on startup | Check Railway deploy logs. Usually caused by a malformed `openclaw.json` |
