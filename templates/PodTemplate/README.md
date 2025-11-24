# Jenkins Pod Template Configuration Guide

## Available Templates

This directory contains multiple pod template options:

1. **`pod-template.yaml`** - Full-featured template with:
   - Jenkins agent container
   - Docker-in-Docker (DinD) sidecar
   - PostgreSQL sidecar
   - Redis sidecar
   - **Use when**: You need Docker commands and database services in your pipeline

2. **`pod-template-alternative.yaml`** - Alternative full-featured template with different resource allocations

3. **`pod-template-minimal.yaml`** - Minimal template with:
   - Jenkins agent container only
   - **Use when**: You don't need Docker or sidecar services (simpler, lighter weight)

## Quick Setup

### Option 1: Using Jenkins UI

1. Navigate to **Manage Jenkins** → **Manage Nodes and Clouds** → **Configure Clouds**
2. Click on your Kubernetes cloud configuration
3. Scroll to **Pod Templates** section
4. Click **Add Pod Template**
5. Configure:
   - **Name**: `jenkins-agent-dind`
   - **Labels**: `docker-agent` (use this label in your pipeline: `agent { label 'docker-agent' }`)
   - **Usage**: Select "Only build jobs with label expressions matching this node"
   - **YAML**: Copy and paste the contents of `pod-template.yaml`

### Option 2: Using Jenkins Configuration as Code (JCasC)

If you're using JCasC, add this to your configuration:

```yaml
jenkins:
  clouds:
    - kubernetes:
        name: "kubernetes"
        serverUrl: "https://your-k8s-api-server"
        # ... other config ...
        templates:
          - name: "jenkins-agent-dind"
            label: "docker-agent"
            yaml: |
              apiVersion: v1
              kind: Pod
              metadata:
                labels:
                  jenkins: agent
              spec:
                # Optional: Only needed for specific permissions (e.g., private registry access)
                # serviceAccountName: jenkins-agent
                containers:
                  - name: jnlp
                    image: ghcr.io/tnware/jenkins-agent:v0.1.3
                    imagePullPolicy: Always
                    resources:
                      requests:
                        memory: "1Gi"
                        cpu: "500m"
                      limits:
                        memory: "4Gi"
                        cpu: "2000m"
                    volumeMounts:
                      - name: workspace-volume
                        mountPath: /home/jenkins/workspace
                      - name: docker-sock
                        mountPath: /var/run/docker.sock
                    env:
                      - name: DOCKER_HOST
                        value: unix:///var/run/docker.sock
                      - name: NVM_DIR
                        value: /home/jenkins/.nvm
                    command:
                      - cat
                    tty: true
                  - name: docker-daemon
                    image: docker:dind
                    imagePullPolicy: Always
                    securityContext:
                      privileged: true
                    resources:
                      requests:
                        memory: "512Mi"
                        cpu: "250m"
                      limits:
                        memory: "2Gi"
                        cpu: "1000m"
                    volumeMounts:
                      - name: docker-sock
                        mountPath: /var/run/docker.sock
                      - name: docker-storage
                        mountPath: /var/lib/docker
                    env:
                      - name: DOCKER_TLS_CERTDIR
                        value: ""
                      - name: DOCKER_HOST
                        value: unix:///var/run/docker.sock
                volumes:
                  - name: workspace-volume
                    emptyDir: {}
                  - name: docker-sock
                    emptyDir: {}
                  - name: docker-storage
                    emptyDir: {}
```

## Service Account Setup (Optional)

**Note**: The service account is optional. If your setup was working before without one, you don't need it. The pod will use the default service account in your namespace.

Only create a service account if you need:

- Access to private container registries (imagePullSecrets)
- Specific RBAC permissions for cluster operations
- Custom security contexts

If you need a service account, create it:

```bash
kubectl create serviceaccount jenkins-agent -n <your-namespace>
```

Then uncomment the `serviceAccountName` line in the pod template YAML.

If you need to pull images from private registries (e.g., GHCR), create a secret and attach it:

```bash
# For pulling from GHCR
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<your-username> \
  --docker-password=<your-token> \
  -n <your-namespace>

kubectl patch serviceaccount jenkins-agent \
  -p '{"imagePullSecrets":[{"name":"ghcr-secret"}]}' \
  -n <your-namespace>
```

## Docker Storage Driver and NFS Compatibility

### Important: NFS Storage Requirements

If you're using an **NFS-backed PersistentVolumeClaim** for the `docker-storage` volume, you **must** use the `vfs` storage driver instead of `overlay2`.

**Why?** The `overlay2` storage driver requires filesystem features (like extended attributes, certain mount options) that NFS doesn't support. You'll see errors like:

```text
failed to mount overlay: invalid argument
failed to start daemon: error initializing graphdriver: driver not supported: overlay2
```

### Storage Driver Configuration

The pod template is configured with `--storage-driver=vfs` for NFS compatibility. This is already set in the template:

```yaml
args: ["--host=unix:///var/run/dind/docker.sock", "--host=tcp://0.0.0.0:2375", "--storage-driver=vfs"]
```

**Storage Driver Options:**

- **`vfs`** (default in template):
  - ✅ Works with NFS
  - ✅ Works with all storage backends
  - ⚠️ Slower performance (no copy-on-write)
  - ⚠️ Higher disk usage

- **`overlay2`** (not compatible with NFS):
  - ✅ Better performance
  - ✅ Lower disk usage
  - ❌ **Does NOT work with NFS**
  - ✅ Works with local storage, EBS, etc.

**If you're NOT using NFS**, you can change the storage driver to `overlay2` for better performance:

```yaml
args: ["--host=unix:///var/run/dind/docker.sock", "--host=tcp://0.0.0.0:2375", "--storage-driver=overlay2"]
```

### Using PVC with NFS

To use a PersistentVolumeClaim with NFS for Docker storage caching:

```yaml
volumes:
  - name: docker-storage
    persistentVolumeClaim:
      claimName: jenkins-docker-cache-pvc
```

The template is already configured to work with NFS PVCs using the `vfs` storage driver.

## Pipeline Usage

In your Jenkinsfile, specify the label:

```groovy
pipeline {
    agent {
        label 'docker-agent'
    }
    // ... rest of your pipeline
}
```

Your existing pipeline with `docker run` commands will work without modifications when using the DinD pod template.

## Minimal Template Usage

If you're using `pod-template-minimal.yaml` (no Docker-in-Docker), you can still use Docker commands if your Kubernetes nodes have Docker socket access, or use alternative container tools like `podman` or `buildah`. However, the minimal template is best for pipelines that don't require Docker at all.

```groovy
pipeline {
    agent {
        label 'jenkins-agent'  // Use a different label for minimal template
    }
    stages {
        stage('Build') {
            steps {
                sh '''
                    # No Docker available, but you can use:
                    # - npm, yarn, maven, gradle, etc.
                    # - kubectl (if configured)
                    # - Any tools installed in the jenkins-agent image
                '''
            }
        }
    }
}
```
