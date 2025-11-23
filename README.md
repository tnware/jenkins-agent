# Jenkins Agent Docker Container

A production-ready Jenkins agent Docker container with essential development tools pre-installed.

## Features

- Based on `jenkins/inbound-agent:latest`
- Pre-installed tools:
  - Python 3 with pip
  - Node.js and npm
  - Docker (Docker-in-Docker support)
  - Build essentials
  - Git and jq
  - curl and wget

## Quick Start

### Pull the Image

**From Docker Hub:**
```bash
docker pull <DOCKERHUB_USERNAME>/jenkins-agent:latest
```

**From GitHub Container Registry:**
```bash
docker pull ghcr.io/<GITHUB_USERNAME>/jenkins-agent:latest
```

### Run the Container

```bash
docker run -it --rm <DOCKERHUB_USERNAME>/jenkins-agent:latest /bin/bash
```

## CI/CD

This repository includes production-ready GitHub Actions workflows for:

- ✅ Automated builds on push to main
- ✅ Multi-platform builds (amd64, arm64)
- ✅ Security scanning with Trivy
- ✅ Dockerfile linting with Hadolint
- ✅ Automated releases with changelog generation
- ✅ Publishing to Docker Hub and GitHub Container Registry

See [.github/workflows/README.md](.github/workflows/README.md) for detailed workflow documentation.

## Building Locally

```bash
docker build -t jenkins-agent:local .
```

## Usage in Jenkins

Configure your Jenkins agent to use this image:

```groovy
pipeline {
    agent {
        docker {
            image 'your-username/jenkins-agent:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'python3 --version'
                sh 'node --version'
                sh 'docker --version'
            }
        }
    }
}
```

## License

[Add your license here]
