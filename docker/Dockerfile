FROM node:22-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git curl procps cron tini \
    python3 jq bubblewrap \
    libglib2.0-0 libnspr4 libnss3 \
    libatk1.0-0 libatk-bridge2.0-0 \
    libdbus-1-3 libcups2 libxkbcommon0 libatspi2.0-0 \
    libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libcairo2 libpango-1.0-0 libasound2 \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
RUN npm install -g @openai/codex@0.130.0
RUN npm install -g @anthropic-ai/claude-code
ENV PATH="/data/.openclaw/bin:/data/.bun/bin:/app/node_modules/.bin:$PATH"
ENV ALPHACLAW_ROOT_DIR=/data
ENV OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json
ENV GSTACK_HOME=/data/.openclaw/.gstack
ENV CODEX_HOME=/data/.codex
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
CMD ["alphaclaw", "start"]
