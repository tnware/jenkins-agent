# Jenkins Agent for Kubernetes

A Jenkins agent Docker image designed to run in Kubernetes with support for Docker-in-Docker (DinD) and sidecar containers.

## Features

- Based on `jenkins/inbound-agent:latest`
- Docker CLI installed and configured
- Python 3 with pip
- Node.js and npm
- NVM (Node Version Manager) for managing Node.js versions
- Build tools and utilities

## Image

The image is published to: `ghcr.io/tnware/jenkins-agent:v0.1.3`

## Usage

This agent is designed to support pipelines that use Docker commands (like `docker run`). There are two approaches:

### Approach 1: Docker-in-Docker (DinD) - Recommended for existing pipelines

This approach allows your existing pipeline to work without modifications. The DinD sidecar provides a Docker daemon that the agent can use.

**Pod Template Configuration:**

Use the `pod-template.yaml` file provided. In Jenkins, configure your Kubernetes cloud plugin with this pod template:

1. Go to **Manage Jenkins** → **Manage Nodes and Clouds** → **Configure Clouds**
2. Select your Kubernetes cloud configuration
3. Add a new Pod Template with the following:
   - **Name**: `jenkins-agent-dind`
   - **Labels**: `docker-agent` (or your preferred label)
   - **YAML**: Copy the contents of `pod-template.yaml`

**Key Points:**

- The DinD container runs with `privileged: true` (required for Docker daemon)
- Docker socket is shared between containers via a volume
- Your pipeline can use `docker run` commands as-is

**Pipeline Usage:**

Your existing pipeline will work without changes. The `docker run` commands will execute against the DinD daemon.

### Approach 2: Sidecar Containers (Alternative)

This approach uses native Kubernetes sidecar containers for PostgreSQL and Redis instead of running them via Docker. This is more efficient but requires pipeline modifications.

**Pod Template Configuration:**

Use the `pod-template-alternative.yaml` file. This includes:

- Main agent container
- DinD sidecar (still needed if you use other Docker commands)
- PostgreSQL sidecar (port 5432)
- Redis sidecar (port 6379)

**Pipeline Modifications Required:**

If you use the sidecar approach, you'll need to modify your pipeline's "Backend: Setup Services" stage. Instead of running Docker containers, the services are already available:

```groovy
stage('Backend: Setup Services') {
    steps {
        script {
            sh '''
                # Services are already running as sidecars
                # Just wait for PostgreSQL to be ready
                for i in $(seq 1 30); do
                    if pg_isready -h localhost -p 5432 -U postgres; then
                        echo "PostgreSQL is ready!"
                        if psql -h localhost -p 5432 -U postgres -d django -c "SELECT 1" > /dev/null 2>&1; then
                            echo "PostgreSQL connection verified!"
                            break
                        fi
                    fi
                    echo "Waiting for PostgreSQL to start... (attempt $i/30)"
                    sleep 2
                done

                # Final connection test
                psql -h localhost -p 5432 -U postgres -d django -c "SELECT 1" || exit 1
            '''
        }
    }
}
```

And remove the cleanup step from the `post` section (containers are managed by Kubernetes).

**Note:** You'll need to install `postgresql-client` in your Dockerfile if using this approach, or use a container with psql available.

## Building the Image

```bash
docker build -t ghcr.io/tnware/jenkins-agent:v0.1.3 .
```

## Requirements

- Kubernetes cluster with Jenkins Kubernetes plugin configured
- Sufficient resources allocated (see resource requests/limits in pod templates)
- **Optional**: Service account (only needed for specific use cases like private registry access)

## Security Considerations

- The DinD container requires `privileged: true`, which has security implications
- Consider using a dedicated namespace for Jenkins agents
- Review and adjust resource limits based on your workload
- For production, consider using a more restrictive security context

## Troubleshooting

### Docker commands not working

- Ensure the DinD sidecar is running: `kubectl logs <pod-name> -c docker-daemon`
- Check Docker socket mount: `ls -la /var/run/docker.sock` in the agent container
- Verify `DOCKER_HOST` environment variable is set correctly

### NVM not found

- Ensure `NVM_DIR` environment variable is set
- Source nvm in your pipeline: `. "$NVM_DIR/nvm.sh"` (as shown in your pipeline)

### PostgreSQL/Redis connection issues

- If using DinD: Check that containers started successfully
- If using sidecars: Verify sidecar containers are running and ports are accessible
- Check network policies if using a service mesh

## License

[Add your license here]
