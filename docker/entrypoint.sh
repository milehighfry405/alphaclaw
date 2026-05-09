#!/bin/sh
# Symlink volume-backed paths into ephemeral /root/ so tools find them after restart
ln -sfn /data/.gbrain /root/.gbrain
# Point OpenClaw CLI at the volume-backed config (not ephemeral /root/.openclaw/)
export OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json
# Ensure gbrain + bun are on PATH
export PATH="/data/.bun/bin:$PATH"
exec "$@"
