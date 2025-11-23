FROM jenkins/inbound-agent:latest

USER root

RUN apt-get update && apt-get install --no-install-recommends -y \
    python3 python3-pip \
    nodejs npm \
    docker.io \
    build-essential \
    git jq \
    curl wget \
    && apt-get clean


# Install Helm
# RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# # Install kubectl
# RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
#     && chmod +x kubectl \
#     && mv kubectl /usr/local/bin

USER jenkins