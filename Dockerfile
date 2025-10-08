# Use Debian latest as the base image
FROM ubuntu:latest AS base

# Install necessary packages (without software-properties-common as it's no more available in Trixie)
RUN apt-get update && apt-get install -y apt-transport-https wget curl gnupg2

# Add the Microsoft GPG key and repository manually
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg && \
    install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    rm /tmp/packages.microsoft.gpg

# Install needed packages on your IDE system
RUN apt-get update && apt-get install -y code

RUN apt-get -y install sudo -y \
    nano \
    git \
    curl \
    ca-certificates \
    bash-completion \
    wget \
    unzip \
    npm \
    ssh && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

FROM base AS dockercli

RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update \
    && apt-get install docker-ce-cli docker-compose-plugin -y \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/



FROM dockercli AS user
# Copy start.sh to the container
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Create a non-root user
RUN useradd -m -d /home/vscodeuser -s /bin/bash vscodeuser && \
    echo 'vscodeuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vscodeuser && \
    chmod 0444 /etc/sudoers.d/vscodeuser && \
    usermod -aG sudo vscodeuser && \
    groupadd -g 988 docker && \
    usermod -aG docker vscodeuser


# Switch to the non-root user
USER vscodeuser

# Set the home directory for the non-root user
ENV HOME=/home/vscodeuser

WORKDIR /home/vscodeuser

# Exécutez le script au lancement du conteneur
ENTRYPOINT ["sh", "/app/start.sh"]
