# Jenkins Pod Templates

This directory contains Kubernetes pod templates for Jenkins agents, organized by feature set.

## Directory Structure

- **`base/`** - Minimal template with just the Jenkins agent container
  - No Docker-in-Docker
  - No sidecar services
  - Use when: You only need basic build tools (Python, Node.js, etc.)

- **`dind/`** - Template with Docker-in-Docker support
  - Includes DinD sidecar for Docker daemon
  - No database/service sidecars
  - Use when: You need Docker commands but don't need PostgreSQL/Redis

- **`sidecars/`** - Template with service sidecars (PostgreSQL, Redis)
  - Includes PostgreSQL and Redis sidecars
  - No Docker-in-Docker
  - Use when: You need database services but don't need Docker commands

- **`sidecars-dind/`** - Full-featured template with both DinD and sidecars
  - Includes Docker-in-Docker sidecar
  - Includes PostgreSQL and Redis sidecars
  - Use when: You need both Docker commands and database services

## Quick Setup

### Using Jenkins UI

1. Navigate to **Manage Jenkins** → **Manage Nodes and Clouds** → **Configure Clouds**
2. Select your Kubernetes cloud configuration
3. Click **Add Pod Template**
4. Configure:
   - **Name**: Choose a descriptive name (e.g., `jenkins-agent-base`, `jenkins-agent-dind`)
   - **Labels**: Choose a label (e.g., `base-agent`, `docker-agent`)
   - **Usage**: Select "Only build jobs with label expressions matching this node"
   - **YAML**: Copy and paste the contents from the appropriate template file

### Using Jenkins Configuration as Code (JCasC)

Add the template to your JCasC configuration:

```yaml
jenkins:
  clouds:
    - kubernetes:
        name: "kubernetes"
        serverUrl: "https://your-k8s-api-server"
        templates:
          - name: "jenkins-agent-base"
            label: "base-agent"
            yaml: |
              # Copy contents from templates/base/pod-template.yaml
```

## Template Details

### Base Template (`base/pod-template.yaml`)

Minimal configuration with just the Jenkins agent:
- Jenkins agent container with standard tools
- Workspace volume
- Resource limits: 1Gi-4Gi memory, 1000m-2000m CPU

### DinD Template (`dind/pod-template.yaml`)

Adds Docker-in-Docker support:
- All features from base template
- Docker daemon sidecar (privileged mode)
- Docker socket shared via volume
- Resource limits: DinD sidecar uses 512Mi-2Gi memory, 2000m-4000m CPU

**Note:** The DinD container requires `privileged: true`, which has security implications.

### Sidecars Template (`sidecars/pod-template.yaml`)

Adds PostgreSQL and Redis sidecars:
- All features from base template
- PostgreSQL sidecar (port 5432)
- Redis sidecar (port 6379)
- Environment variables configured for service connections

### Sidecars-DinD Template (`sidecars-dind/pod-template.yaml`)

Full-featured template combining all features:
- All features from DinD template
- All features from sidecars template
- Use when you need both Docker and database services

**Alternative version:** `pod-template-alternative.yaml` uses different resource allocations and `vfs` storage driver for NFS compatibility.

## Service Account (Optional)

The service account is optional and only needed for:
- Access to private container registries (imagePullSecrets)
- Specific RBAC permissions for cluster operations
- Custom security contexts

To use a service account, uncomment the `serviceAccountName` line in the template and create the service account:

```bash
kubectl create serviceaccount jenkins-agent -n <your-namespace>
```

## Pipeline Usage

In your Jenkinsfile, specify the appropriate label:

```groovy
pipeline {
    agent {
        label 'base-agent'  // or 'docker-agent', etc.
    }
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building..."'
            }
        }
    }
}
```

## Storage Driver Configuration

The DinD templates use `overlay2` storage driver by default. If you're using NFS-backed storage, use the alternative template which uses `vfs` storage driver, or modify the args:

```yaml
args: ["--host=unix:///var/run/dind/docker.sock", "--host=tcp://0.0.0.0:2375", "--storage-driver=vfs"]
```

## Resource Requirements

Adjust resource requests and limits in the templates based on your workload:

- **Base template**: Lightweight, suitable for simple builds
- **DinD templates**: Higher resource usage due to Docker daemon
- **Sidecars templates**: Additional memory/CPU for PostgreSQL and Redis

Monitor your cluster resources and adjust as needed.
