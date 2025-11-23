FROM jenkins/inbound-agent:latest

USER root

# Install prerequisites
RUN apt-get update && apt-get install --no-install-recommends -y \
    python3 python3-pip \
    nodejs npm \
    build-essential \
    git jq \
    curl wget \
    ca-certificates \
    gnupg \
    lsb-release \
    && apt-get clean

# Install Docker using official Docker repository
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    && apt-get clean


# Install Helm
# RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# # Install kubectl
# RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
#     && chmod +x kubectl \
#     && mv kubectl /usr/local/bin

USER jenkins