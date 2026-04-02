# OpenClaw Railway Template

One-click deploy of [OpenClaw](https://openclaw.dev) on [Railway](https://railway.com) — a pre-configured gateway with Telegram channel support.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/9MUg0t?referralCode=MPKvO7&utm_medium=integration&utm_source=template&utm_campaign=generic)

## What You Get

- OpenClaw gateway with token auth
- Telegram bot channel (allowlist DM policy)
- Health checks (`/health`, `/readyz`)
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
6. The gateway starts and Railway healthchecks `/health`

## Local Development

```bash
cp .env.example .env
# Fill in your values
docker build -t openclaw-railway .
docker run --env-file .env -p 18789:18789 openclaw-railway
```
