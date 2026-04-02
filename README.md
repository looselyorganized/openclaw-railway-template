# OpenClaw Railway Template

Deploy an [OpenClaw](https://openclaw.ai) AI agent gateway to [Railway](https://railway.app) in one click.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/template/openclaw)

## What is OpenClaw?

OpenClaw is an AI agent gateway powered by Anthropic's Claude. This template gives you a production-ready deployment with:

- **Telegram bot integration** for chatting with your AI agent
- **Control UI** for managing agents and configuration
- **Token-based authentication** for secure API access
- **Web search** via Brave Search API (optional)
- **Semantic memory** via OpenAI embeddings (optional)

## Quick Start

### 1. Deploy to Railway

Click the "Deploy on Railway" button above, or:

1. Fork this repository
2. Create a new project on [Railway](https://railway.app)
3. Connect your forked repo
4. Add the required environment variables (see below)
5. Deploy

Railway will automatically detect the `Dockerfile` and build the service.

### 2. Set Environment Variables

In your Railway service settings, add the following variables:

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | Your [Anthropic API key](https://console.anthropic.com/) for Claude |
| `TELEGRAM_BOT_TOKEN` | Yes | Your Telegram bot token from [@BotFather](https://t.me/BotFather) |
| `OPENCLAW_GATEWAY_TOKEN` | Yes | A secret token for authenticating with the gateway API |
| `OPENAI_API_KEY` | No | OpenAI API key for semantic memory embeddings |
| `BRAVE_SEARCH_API_KEY` | No | [Brave Search API key](https://brave.com/search/api/) for web search |

### 3. Access the Control UI

Once deployed, your service will be available on port `18789`. Railway will assign a public URL automatically. Visit it to access the OpenClaw control UI.

Authenticate using your `OPENCLAW_GATEWAY_TOKEN`.

## Configuration

The default configuration lives in `openclaw.json`:

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

- **`channels.telegram.allowFrom`** — Array of Telegram user IDs allowed to message the bot. Find your ID using [@userinfobot](https://t.me/userinfobot).
- **`channels.telegram.dmPolicy`** — Set to `"allowlist"` to restrict access or `"open"` to allow anyone.
- **`agents.defaults.model`** — The default Claude model for agents.

Config is seeded on first boot and persisted at `~/.openclaw/openclaw.json` inside the container. The `TELEGRAM_BOT_TOKEN` is injected automatically at startup from the environment variable.

## Project Structure

```
.
├── Dockerfile          # Builds from the official OpenClaw image
├── entrypoint.sh       # First-boot config seeding & token injection
├── openclaw.json       # Default configuration template
└── .env.example        # Environment variable reference
```

## How It Works

1. The `Dockerfile` pulls the official `ghcr.io/openclaw/openclaw:latest` image
2. On first boot, `entrypoint.sh` copies the default config and injects your Telegram bot token
3. `openclaw doctor --fix --yes` validates and auto-fixes the configuration
4. The gateway starts and listens on port `18789`

## Local Development

```bash
# Copy the env template and fill in your keys
cp .env.example .env

# Build and run with Docker
docker build -t openclaw-gateway .
docker run --env-file .env -p 18789:18789 openclaw-gateway
```

Visit `http://localhost:18789` to access the control UI.

## License

See the [OpenClaw documentation](https://openclaw.ai) for licensing details.
