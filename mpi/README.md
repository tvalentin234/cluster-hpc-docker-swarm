
# Imagem MPI (MPICH 4.1.3) com OpenSSH

- Base: Ubuntu 22.04
- Inclui MPICH 4.1.3 (compilado), OpenSSH e utilitários
- `generate_hostfile` resolve `tasks.compute-daemon` via DNS do Swarm e escreve `/etc/mpi/hostfile`

Build/push:

```bash
docker build -t registry.local/mpi-mpich:4.1.3 ./mpi
docker push registry.local/mpi-mpich:4.1.3
```

Execução típica em job (exemplo):

```bash
mpirun -f /etc/mpi/hostfile -np 8 --bind-to core /path/app_mpi
```
