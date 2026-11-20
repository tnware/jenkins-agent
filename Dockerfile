FROM jenkins/inbound-agent:jdk21@sha256:5c9b6fe9a7ccc50bcdcb039d64ac2c2aa3fe9cde3a6ba6f7c80058257452d391

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
    # Network and Debugging Tools
    netcat-openbsd dnsutils iputils-ping \
    # Text Processing
    gettext-base \
    # Dependencies for WeasyPrint/Pango/Cairo (PDF generation)
    libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf-2.0-0 libffi-dev shared-mime-info \
    # Database clients
    postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Wails dependencies (GTK3 and WebKit2GTK)
# Try libwebkit2gtk-4.0-dev first, fallback to libwebkit2gtk-4.1-dev or libwebkit2gtk-dev if not available
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    pkg-config \
    libgtk-3-dev && \
    (apt-get install --no-install-recommends -y libwebkit2gtk-4.0-dev || \
     apt-get install --no-install-recommends -y libwebkit2gtk-4.1-dev || \
     apt-get install --no-install-recommends -y libwebkit2gtk-dev || \
     echo "Warning: Could not install libwebkit2gtk-dev package. Run 'wails doctor' to check dependencies.") && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install yq
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Install Helm
RUN curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz && \
    tar -zxvf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm.tar.gz

# Install kubectl
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin

# Install Golang
ENV GO_VERSION=1.22.0
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/home/jenkins/go
ENV PATH=$PATH:$GOPATH/bin

# Create GOPATH directory and install wails
# Note: Run 'wails doctor' after container startup to verify all dependencies are correctly installed
RUN mkdir -p /home/jenkins/go/bin && \
    chown -R jenkins:jenkins /home/jenkins/go && \
    su jenkins -c "go install github.com/wailsapp/wails/v2/cmd/wails@latest" && \
    su jenkins -c "wails version"

# Add the jenkins user to the docker group
RUN usermod -aG docker jenkins

# Install NVM (Node Version Manager) for the jenkins user
# Create directory and set ownership before switching user
RUN mkdir -p /home/jenkins/.nvm && \
    chown -R jenkins:jenkins /home/jenkins/.nvm

USER jenkins
ENV NVM_DIR=/home/jenkins/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    echo "export NVM_DIR=\"\$HOME/.nvm\"" >> /home/jenkins/.bashrc && \
    echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"" >> /home/jenkins/.bashrc && \
    echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"" >> /home/jenkins/.bashrc

# Verify the agent runs on Java 21 before a build can publish the image.
RUN java -XshowSettings:properties -version 2>&1 \
    | grep -Eq '^[[:space:]]*java\.specification\.version = 21[[:space:]]*$' && \
    java -jar /usr/share/jenkins/agent.jar -version
