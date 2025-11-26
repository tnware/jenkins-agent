# Jenkins Agent for Kubernetes

A Jenkins agent Docker image designed to run in Kubernetes.

## Features

- Based on `jenkins/inbound-agent:latest`
- Docker CLI installed and configured
- Python 3 with pip
- Node.js and npm
- NVM (Node Version Manager) for managing Node.js versions
- Build tools and utilities (git, jq, curl, wget, etc.)
- Kubernetes tools (kubectl, Helm)
- YAML processing (yq)

## Image

The image is published to: `ghcr.io/tnware/jenkins-agent:latest`

## Building the Image

```bash
docker build -t ghcr.io/tnware/jenkins-agent:v0.1.6 .
```

Or use the Makefile:

```bash
make build
make push
```

## Requirements

- Kubernetes cluster with Jenkins Kubernetes plugin configured
- See `templates/` directory for pod template configurations

## License

See [LICENSE](LICENSE) file for details.
