FROM jenkins/inbound-agent:latest

USER root

# Install prerequisites
RUN apt-get update && apt-get install --no-install-recommends -y \
    python3 python3-pip python3-venv python-is-python3 \
    nodejs npm \
    build-essential \
    git jq \
    curl wget \
    ca-certificates \
    gnupg \
    lsb-release \
    # Dependencies for WeasyPrint/Pango/Cairo (PDF generation)
    libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf-2.0-0 libffi-dev shared-mime-info \
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

# Add the jenkins user to the docker group
RUN usermod -aG docker jenkins

# Install NVM (Node Version Manager) for the jenkins user
# Create directory and set ownership before switching user
RUN mkdir -p /home/jenkins/.nvm && \
    chown -R jenkins:jenkins /home/jenkins/.nvm

USER jenkins
ENV NVM_DIR=/home/jenkins/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/jenkins/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/jenkins/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/jenkins/.bashrc

# Install Helm
# RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# # Install kubectl
# RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
#     && chmod +x kubectl \
#     && mv kubectl /usr/local/bin