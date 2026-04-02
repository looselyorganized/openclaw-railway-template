FROM ghcr.io/openclaw/openclaw:latest

COPY openclaw.json /app/openclaw.json.default
COPY --chmod=755 entrypoint.sh /app/entrypoint.sh

ENV NODE_ENV=production

CMD ["/app/entrypoint.sh"]
