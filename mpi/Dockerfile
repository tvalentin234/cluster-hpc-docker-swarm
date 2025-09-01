
FROM ubuntu:22.04

ARG MPICH_VERSION=4.1.3
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \      build-essential ca-certificates curl wget git \      openssh-server iputils-ping dnsutils net-tools \      python3 python3-pip \      libnuma-dev \    && rm -rf /var/lib/apt/lists/*

# Build MPICH from source (4.1.3)
WORKDIR /tmp
RUN wget -q https://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz && \    tar xzf mpich-${MPICH_VERSION}.tar.gz && \    cd mpich-${MPICH_VERSION} && \    ./configure --prefix=/usr/local && make -j"$(nproc)" && make install && \    ldconfig && \    rm -rf /tmp/*

# SSH config
RUN mkdir -p /var/run/sshd /root/.ssh /etc/mpi && \    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd && \    echo "StrictHostKeyChecking no" > /root/.ssh/config

COPY entrypoint.sh /entrypoint.sh
COPY generate_hostfile.sh /usr/local/bin/generate_hostfile
RUN chmod +x /entrypoint.sh /usr/local/bin/generate_hostfile

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
