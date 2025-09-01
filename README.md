# cluster-hpc-docker-swarm
# Cluster HPC com Docker Swarm (2 managers + 8 workers)

Este projeto entrega **passo a passo operacional** e os artefatos (stacks, scripts e imagens) para montar um **cluster HPC** com:
- **Docker Swarm**
- **MPICH 4.1.3** (com OpenSSH) para MPI
- **Observabilidade Essencial**: Prometheus, Alertmanager, Grafana, Pushgateway
- **Exporters**: node_exporter (hosts) e cAdvisor (containers)
- **Dashboards**: *Infra Essentials* e *Encadeado compacto*
- **Orquestração do pipeline NEWAVE/DECOMP** via Airflow (ou JS7 como alternativa)
- **Publicação de métricas** no Pushgateway (início/fim/erro/tempo)

> Documentos e materiais de referência podem ser mantidos em `docs/` (ex.: a proposta comercial do escopo).

---

## 🧭 Topologia alvo

- **Managers**: 2 nós (ex.: `mgr01`, `mgr02`)
- **Workers**: 8 nós (ex.: `wrk01`…`wrk08`)
- **Redes overlay**:
  - `mpi_net` — tráfego MPI/SSH entre *tasks* MPI
  - `svc_net` — serviços (observabilidade, orquestração)

> Em ambientes de missão crítica, considere **3 managers** para maior resiliência de quórum.

---

## 📁 Estrutura do repositório

cluster-hpc-docker-swarm/
├─ README.md
├─ .gitignore
├─ docs/
│ └─ Proposta-Comercial-Cluster-HPC-Docker-Swarm.pdf # (opcional)
├─ scripts/
│ ├─ disable-smt.sh # desativa SMT/HT (opcional)
│ ├─ firewall-ufw.sh # abre portas (Ubuntu/UFW)
│ ├─ firewall-firewalld.sh # abre portas (RHEL/firewalld)
│ └─ label-workers-compute.sh # adiciona label role=compute
├─ stacks/
│ ├─ observability.yml # Prometheus/Alertmanager/Grafana/PGW/node_exporter/cAdvisor
│ ├─ mpi.yml # compute-daemon (global) + runner
│ └─ airflow.yml # Airflow LocalExecutor + Postgres
├─ observability/
│ ├─ prometheus/prometheus.yml
│ ├─ prometheus/rules/alerts.yml
│ └─ alertmanager/alertmanager.yml
├─ grafana/provisioning/
│ ├─ datasources/datasource.yml # Prometheus datasource
│ └─ dashboards/
│ ├─ provider.yml
│ └─ json/
│ ├─ infra-essentials.json
│ └─ encadeado-compacto.json
├─ mpi/
│ ├─ Dockerfile # MPICH 4.1.3 + OpenSSH
│ ├─ entrypoint.sh
│ ├─ generate_hostfile.sh # hostfile via DNS do Swarm (tasks.compute-daemon)
│ └─ README.md
└─ airflow/dags/
├─ newave_decomp_dag.py # DAG exemplo
└─ wrappers/
├─ push_metric.sh # publica métricas no Pushgateway
├─ newave_wrapper.sh # validação/execução/logs (placeholder)
└─ decomp_wrapper.sh # validação/execução/logs (placeholder)


---

## ✅ Pré-requisitos (todos os nós)

- Linux (Ubuntu 24.04 LTS **ou** RHEL 10)
- Docker Engine ≥ 24 + Docker Compose plugin
- Usuário com sudo
- Sincronização de horário (chrony/ntpd)
- Hostnames únicos e resolução interna consistente (DNS ou `/etc/hosts`)
- Conectividade entre nós (veja portas 👇)

Instalação rápida do Docker (Ubuntu):

```bash
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER
newgrp docker

🔧 Ajustes de CPU (opcional, quando aplicável)

Desativar SMT/Hyper-Threading para workloads MPI mais previsíveis:

Temporário: echo off | sudo tee /sys/devices/system/cpu/smt/control

Permanente: adicionar nosmt no GRUB e reiniciar

Pinagem/afinidade: em jobs MPI, use mpirun --bind-to core e planeje placement no Swarm com constraints e resources.

Scripts de apoio: scripts/disable-smt.sh.

| Categoria       | Portas                                                                             |
| --------------- | ---------------------------------------------------------------------------------- |
| Docker Swarm    | **2377/TCP** (mgmt), **7946/TCP+UDP**, **4789/UDP**                                |
| SSH             | **22/TCP**                                                                         |
| Serviços (apps) | **6000–9000/TCP** (ajuste conforme app)                                            |
| Observabilidade | **9090** Prometheus, **9091** Pushgateway, **9093** Alertmanager, **3000** Grafana |


Scripts prontos:

Ubuntu/UFW: scripts/firewall-ufw.sh

🐳 Swarm: init, quórum, labels
1) Inicializar Swarm no manager principal
# no mgr01
docker swarm init --advertise-addr <IP_MGR01>

# tokens
docker swarm join-token manager
docker swarm join-token worker

2) Entrar com o 2º manager e os 8 workers
# mgr02 (como manager)
docker swarm join --token <TOKEN_MANAGER> <IP_MGR01>:2377

# workers (cada um)
docker swarm join --token <TOKEN_WORKER> <IP_MGR01>:2377

Verifique: docker node ls (deve listar 10 nós).
Com 2 managers, o quórum é 2 (Leader + Reachable). Para maior resiliência, considere 3 managers.

3) Labels e roles (workers como compute)
# em um manager
./scripts/label-workers-compute.sh
# ou manual:
# docker node update --label-add role=compute wrk01
# ...

🌐 Redes overlay

Crie as redes (em um manager):

docker network create -d overlay --attachable mpi_net
docker network create -d overlay --attachable svc_net

📊 Observabilidade Essencial

Suba a stack:

docker stack deploy -c stacks/observability.yml observ


Acessos padrão:

Prometheus: http://<manager>:9090

Alertmanager: http://<manager>:9093

Pushgateway: http://<manager>:9091

Grafana: http://<manager>:3000 (login inicial admin/admin → troque)

Dashboards provisionados:

Infra Essentials

Encadeado compacto

Alertas essenciais (exemplos, em observability/prometheus/rules/alerts.yml):

Host/serviço indisponível (up == 0)

CPU, memória e disco altos

Pipeline stalled (sem push de métricas por tempo X)

Alertmanager: configure destinatários (email/Slack/webhook) em observability/alertmanager/alertmanager.yml.

🧪 Runtime MPI (MPICH 4.1.3)
Imagem MPICH com OpenSSH

Edite a referência do registry e faça build/push:

# ajuste REGISTRY (ex.: registry.local, ghcr.io/owner, etc.)
export REGISTRY="registry.local"
docker build -t $REGISTRY/mpi-mpich:4.1.3 ./mpi
docker push $REGISTRY/mpi-mpich:4.1.3

Daemon global nos workers e runner
docker stack deploy -c stacks/mpi.yml mpi


compute-daemon roda global nos nós com role=compute e mantém sshd disponível.

mpi-runner (no manager) gera /etc/mpi/hostfile dinamicamente via DNS do Swarm (tasks.compute-daemon) usando mpi/generate_hostfile.sh.

Teste rápido:

# entrar no runner (ou executar um comando via service)
docker ps | grep mpi-runner
docker exec -it <container_mpi-runner> bash

# dentro do container:
generate_hostfile
cat /etc/mpi/hostfile
mpirun -f /etc/mpi/hostfile -np 8 --bind-to core hostname


Ajuste slots, binding e mapping (--map-by, --bind-to) conforme a topologia de CPU.

⛓️ Encadeado NEWAVE/DECOMP (Airflow ou JS7)
Airflow (LocalExecutor)
docker stack deploy -c stacks/airflow.yml airflow


UI: http://<manager>:8080 (admin/admin na criação)

DAG exemplo: airflow/dags/newave_decomp_dag.py

Wrappers: airflow/dags/wrappers/ publicam métricas no Pushgateway (push_metric.sh)

Personalize:

Validação de decks, timeouts, coleta de logs (incluir comandos reais do NEWAVE/DECOMP nos wrappers)

Schedules e dependências do DAG

Roteiros de incidentes no Alertmanager

Alternativa: JS7 (Open Source)

Estruture jobs/orders análogos aos tasks do Airflow e reutilize os wrappers para métricas.

Mantenha o mesmo Pushgateway e dashboards.

🔒 Segurança (boas práticas)

Acesse observabilidade apenas via VPN / IPs permitidos (firewall/ingress)

Use Docker Swarm Secrets para credenciais

Considere docker swarm update --autolock=true

Faça patching regular de SO/Kernel e Engine Docker

Limite o escopo de portas 6000–9000/TCP aos serviços que precisarem

🧰 Troubleshooting rápido

docker node ls mostra nó Down/Unknown
Verifique rede/firewall, /etc/hosts, DNS e hora (NTP).

Falha ao criar overlay (ingress/VXLAN)
Libere UDP 4789 e TCP/UDP 7946 entre nós; confirme que não há conflitos de MTU.

Grafana sem dashboards
Cheque grafana/provisioning/... montado e logs do container.

Alertas não chegam
Configure alertmanager.yml com receiver real (email/Slack/webhook) e reinicie.

tasks.compute-daemon não resolve
O serviço compute-daemon precisa estar em mode: global e as redes criadas; confira docker service ps e DNS do Swarm.

📚 Handover

Runbook: este README + pastas stacks/, scripts/, observability/, airflow/, mpi/
