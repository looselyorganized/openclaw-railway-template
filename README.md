# OpenClaw Railway Template

One-click deploy of [OpenClaw](https://openclaw.dev) on [Railway](https://railway.com) — a pre-configured gateway with Telegram channel support.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/9MUg0t?referralCode=MPKvO7&utm_medium=integration&utm_source=template&utm_campaign=generic)

![Version](https://img.shields.io/badge/version-1.0.1-blue)

## What You Get

- OpenClaw gateway with token auth
- Telegram bot channel (allowlist DM policy)
- Health checks (`/health`, `/readyz`)
- Auto-restart on failure (10 retries)

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Powers the agent's conversational model (Claude) |
| `OPENCLAW_GATEWAY_TOKEN` | Random string to secure gateway API access |
| `TELEGRAM_BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_ALLOW_FROM` | Your Telegram user ID (comma-separated for multiple users) |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_MODEL` | `anthropic/claude-sonnet-4-6` | Default agent model |
| `TELEGRAM_DM_POLICY` | `allowlist` | DM access policy: `allowlist` or `open` |
| `CONTROL_UI_ENABLED` | `true` | Enable gateway Control UI (true/false) |
| `OPENAI_API_KEY` | — | Alternative LLM provider for GPT models (fallback if no Anthropic key) |
| `BRAVE_API_KEY` | — | Enables the web_search tool for live web results |

## Volume

This template attaches a persistent volume at `/root/.openclaw` to preserve config, conversation history, and agent state across redeploys.

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
