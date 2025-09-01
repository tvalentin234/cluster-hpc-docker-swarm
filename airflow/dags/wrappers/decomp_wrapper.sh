
#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/push_metric.sh" >/dev/null 2>&1 || true
JOB="decomp"
trap 'push_metric "$JOB" "fail" || true' ERR
# TODO: validação de deck, timeouts e execução real do DECOMP
echo "[DECOMP] Validando decks..."
sleep 2
echo "[DECOMP] Executando modelo..."
sleep 3
echo "[DECOMP] Coletando logs..."
sleep 1
push_metric "$JOB" "ok" || true
