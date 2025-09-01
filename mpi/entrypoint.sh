
#!/usr/bin/env bash
set -euo pipefail

# Gera chaves de host se não existirem
if [[ ! -f /etc/ssh/ssh_host_rsa_key ]]; then
  ssh-keygen -A
fi

# Opcional: aceita chave pública via variável de ambiente AUTH_KEY
if [[ -n "${AUTH_KEY:-}" ]]; then
  mkdir -p /root/.ssh
  echo "$AUTH_KEY" >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi

# Gera hostfile dinâmico, se possível
generate_hostfile || true

# Inicia sshd em segundo plano
/usr/sbin/sshd

# Se CMD foi passado, executa; senão, fica rodando
if [[ "$#" -gt 0 ]]; then
  exec "$@"
else
  tail -f /dev/null
fi
