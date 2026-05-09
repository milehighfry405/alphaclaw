#!/bin/sh
# Symlink volume-backed paths into ephemeral /root/ so tools find them after restart
ln -sfn /data/.gbrain /root/.gbrain
ln -sfn /data/.openclaw/gstack-home /root/.gstack
export OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json
export PATH="/data/.openclaw/bin:/data/.bun/bin:$PATH"
exec "$@"
