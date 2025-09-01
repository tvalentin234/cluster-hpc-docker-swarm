
#!/usr/bin/env bash
set -euo pipefail
HOSTS_FILE="/etc/mpi/hostfile"
SERVICE_NAME="${SERVICE_NAME:-compute-daemon}"
TASKS="tasks.${SERVICE_NAME}"

# Resolve IPs via DNS do Swarm para tasks.<service>
IPS=$(getent ahostsv4 "$TASKS" | awk '{print $1}' | sort -u || true)
if [[ -z "${IPS}" ]]; then
  echo "Nenhum IP resolvido para ${TASKS} (ainda)." >&2
  exit 0
fi

# Por padrão, 1 slot por nó (ajuste conforme necessário)
> "$HOSTS_FILE"
for ip in $IPS; do
  echo "${ip} slots=1" >> "$HOSTS_FILE"
done

echo "Hostfile gerado em ${HOSTS_FILE}:"
cat "$HOSTS_FILE"
