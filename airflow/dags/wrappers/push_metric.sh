
#!/usr/bin/env bash
set -euo pipefail
PG="${PUSHGATEWAY_URL:-http://pushgateway:9091}"
JOB="${1:-job}"
STATUS="${2:-ok}"
TS=$(date +%s)
cat <<EOF | curl --data-binary @- "${PG}/metrics/job/${JOB}"
pipeline_status{job="${JOB}"} $([ "$STATUS" = "ok" ] && echo 1 || echo 0)
push_time_seconds ${TS}
EOF
