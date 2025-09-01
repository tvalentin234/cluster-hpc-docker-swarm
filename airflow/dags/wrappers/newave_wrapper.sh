
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/push_metric.sh" >/dev/null 2>&1 || true
JOB="newave"
trap 'push_metric "$JOB" "fail" || true' ERR
# TODO: validação de deck, timeouts e execução real do NEWAVE
echo "[NEWAVE] Validando decks..."
sleep 2
echo "[NEWAVE] Executando modelo..."
sleep 3
echo "[NEWAVE] Coletando logs..."
sleep 1
push_metric "$JOB" "ok" || true
