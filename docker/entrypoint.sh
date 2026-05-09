#!/bin/sh
# Symlink volume-backed paths into ephemeral /root/ so tools find them after restart
ln -sfn /data/.gbrain /root/.gbrain
ln -sfn /data/.openclaw/gstack-home /root/.gstack
ln -sfn /data/.claude /root/.claude
export OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json
export PATH="/data/.openclaw/bin:/data/.bun/bin:$PATH"

# Trust the persistent brain checkout even when container UID/GID changes across rebuilds.
git config --global --add safe.directory /data/brain || true

# Repair the local CLI operator device-token cache before the gateway starts.
# This is not a readiness race: after the rebuild, the persisted CLI device token
# had only operator.read even though the paired device was approved for
# operator.write. Keep the token scopes aligned with already-approved scopes;
# do not grant admin here.
python3 - <<'PY' || true
import json, time
from pathlib import Path

base = Path('/data/.openclaw')
device_path = base / 'identity/device.json'
local_auth_path = base / 'identity/device-auth.json'
paired_path = base / 'devices/paired.json'

if not (device_path.exists() and local_auth_path.exists() and paired_path.exists()):
    raise SystemExit(0)

device_id = json.loads(device_path.read_text()).get('deviceId')
local_auth = json.loads(local_auth_path.read_text())
paired = json.loads(paired_path.read_text())
entry = paired.get(device_id)
if not entry:
    raise SystemExit(0)

approved = set(entry.get('approvedScopes') or entry.get('scopes') or [])
# Only repair devices that are already approved for write/admin. Never escalate
# a read-only device to write from entrypoint.
if 'operator.write' not in approved and 'operator.admin' not in approved:
    raise SystemExit(0)

wanted = set(approved)
if 'operator.write' in wanted or 'operator.admin' in wanted:
    wanted.add('operator.read')
wanted = sorted(wanted)
changed = False

paired_token = entry.setdefault('tokens', {}).get('operator')
if paired_token and sorted(paired_token.get('scopes') or []) != wanted:
    paired_token['scopes'] = wanted
    paired_token['rotatedAtMs'] = paired_token.get('rotatedAtMs') or int(time.time() * 1000)
    changed = True

local_token = local_auth.setdefault('tokens', {}).get('operator')
if local_token and sorted(local_token.get('scopes') or []) != wanted:
    local_token['scopes'] = wanted
    local_token['updatedAtMs'] = int(time.time() * 1000)
    changed = True

if changed:
    paired_path.write_text(json.dumps(paired, indent=2) + '\n')
    local_auth_path.write_text(json.dumps(local_auth, indent=2) + '\n')
PY

cron

# Start GBrain Minions supervisor + worker after rebuild. It supervises the
# worker process itself; keep it outside the OpenClaw gateway process tree so a
# gateway reload does not stop job processing.
if command -v gbrain >/dev/null 2>&1; then
  if ! gbrain jobs supervisor status --json 2>/dev/null | grep -q '"running": true'; then
    nohup gbrain jobs supervisor start >> /var/log/gbrain-supervisor.log 2>&1 &
  fi
fi

exec "$@"
