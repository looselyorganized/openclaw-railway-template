# RailClaw - OpenClaw Railway Template

![Version](https://img.shields.io/badge/version-1.1.0-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Docker](https://img.shields.io/badge/docker-ghcr.io%2Fopenclaw%2Fopenclaw-blue?logo=docker) ![Railway](https://img.shields.io/badge/deploy-Railway-blueviolet?logo=railway) ![OpenClaw](https://img.shields.io/badge/powered%20by-OpenClaw-red)

RailClaw is a secure, containerized, one-click deploy of [OpenClaw](https://openclaw.dev) on [Railway](https://railway.com) — a pre-configured gateway with Control UI, token auth, channel health monitoring and persistent storage. No manual config files, no CLI setup, just deploy and connect.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/railclaw-1?referralCode=MPKvO7&utm_medium=integration&utm_source=template&utm_campaign=generic)

## About Hosting RailClaw

Hosting RailClaw requires a persistent process that stays online to maintain connections to messaging channels and handle incoming requests. The gateway needs API keys for your chosen LLM provider (Anthropic, OpenAI) and a secure gateway auth token.

Railway handles the container lifecycle, health checks, and automatic restarts — so the gateway stays available without manual intervention. Configuration is injected via environment variables at deploy time, with no files to manage.

## Common Use Cases

- Run a personal AI assistant on Telegram with allowlist-based access control
- Deploy a customer-facing conversational agent backed by Claude or GPT models
- Host a multi-channel gateway that bridges AI models to messaging platforms like Telegram, WhatsApp, Discord, and Slack

## Dependencies for RailClaw Hosting

### Required

- `ANTHROPIC_API_KEY` — Powers the agent's conversational model (Claude)
- `OPENCLAW_GATEWAY_TOKEN` — Random string to secure gateway API access. Generate one with:
  ```bash
  openssl rand -hex 32
  ```
- `PORT` — Must be set to `18789`

### Optional

- `OPENAI_API_KEY` — Alternative LLM provider for GPT models
- `BRAVE_API_KEY` — Enables the web_search tool for live web results
- `OPENCLAW_MODEL` — Default agent model (default: `anthropic/claude-sonnet-4-6`)

### Deployment Dependencies

- https://github.com/looselyorganized/railclaw
- https://docs.openclaw.ai
- https://github.com/openclaw/openclaw
- https://ghcr.io/openclaw/openclaw
- Healthcheck path: `/health`
- Volume mount: `/root/.openclaw`

## Implementation Details

This template deploys a minimal gateway with the Control UI enabled. To add channels (Telegram, WhatsApp, Discord, Slack), configure agents, or manage cron jobs after deployment, use the Control UI.

### Accessing the Control UI

The gateway logs a tokenized dashboard URL on startup. To find it:

1. Open your service in the Railway dashboard
2. Click the **Deployments** tab
3. Select the active deployment
4. Look for the `Dashboard:` line in the logs

The URL follows this pattern:

```
https://<your-railway-domain>/#token=<your-OPENCLAW_GATEWAY_TOKEN>
```

The `#token=` fragment auto-fills authentication in the browser — just click and connect. The token is never sent to the server (URL fragments stay client-side).

From the Control UI you can:

- Chat with the agent directly
- Configure channels — Telegram, WhatsApp, Discord, Slack, and more
- Manage agents, sessions, and cron jobs
- Edit gateway config live

### Security Notes

This template sets `dangerouslyDisableDeviceAuth: true` in the gateway config. This is required because OpenClaw's default device pairing flow requires CLI access to approve new browsers (`openclaw devices approve`), which isn't possible inside a Railway container.

With this flag disabled, **token auth is the sole protection** for the Control UI. Your `OPENCLAW_GATEWAY_TOKEN` is effectively your admin password — treat it accordingly:

- Use a strong, random token (64+ hex characters recommended)
- Don't share the tokenized dashboard URL publicly
- Rotate the token by updating the env var and redeploying

### How It Works

This template pulls the latest tag of the official OpenClaw Docker image (`ghcr.io/openclaw/openclaw:latest`), so every Railway deployment builds against the most current stable release.

The gateway runs as a single containerized service with built-in health checks, automatic restart on failure, and all configuration injected via environment variables — no sidecar services, no manual config files.

A persistent volume at `/root/.openclaw` preserves config, conversation history, and agent state across redeploys.

## Why Deploy RailClaw on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying RailClaw on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
