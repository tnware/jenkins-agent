# GitHub Actions Workflows

This repository includes production-ready GitHub Actions workflows for building, testing, and publishing the Jenkins agent Docker container.

## Workflows Overview

### 1. CI Workflow (`.github/workflows/ci.yml`)
- **Triggers**: Pull requests and pushes to `main`
- **Purpose**: Continuous Integration checks
- **Jobs**:
  - **lint-dockerfile**: Lints the Dockerfile using Hadolint
  - **validate-dockerfile**: Validates Dockerfile syntax
  - **test-build**: Builds the image and runs basic functionality tests

### 2. Docker Build and Publish (`.github/workflows/docker-build-publish.yml`)
- **Triggers**:
  - Pushes to `main` branch
  - Version tags (e.g., `v1.0.0`)
  - Pull requests (build only, no push)
  - Manual workflow dispatch
- **Purpose**: Build and publish Docker images to multiple registries
- **Jobs**:
  - **build-and-publish**: Builds multi-platform images (amd64, arm64) and publishes to:
    - Docker Hub
    - GitHub Container Registry (ghcr.io)
  - **security-scan**: Runs Trivy vulnerability scans
  - **test**: Tests the built image for required tools

### 3. Docker Security Scan (`.github/workflows/docker-scan.yml`)
- **Triggers**:
  - Pushes to `main`
  - Version tags
  - Pull requests
  - Weekly schedule (Sundays)
  - Manual dispatch
- **Purpose**: Comprehensive security scanning
- **Jobs**:
  - **security-scan**:
    - Trivy vulnerability scanning
    - Hadolint Dockerfile linting
    - Uploads results to GitHub Security tab

### 4. Release Workflow (`.github/workflows/release.yml`)
- **Triggers**: Version tags (e.g., `v1.0.0`)
- **Purpose**: Creates GitHub releases with changelog
- **Jobs**:
  - **release**: Generates changelog and creates GitHub release

## Setup Instructions

### Required Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

1. **DOCKERHUB_USERNAME**: Your Docker Hub username
2. **DOCKERHUB_TOKEN**: Your Docker Hub access token
   - Create at: https://hub.docker.com/settings/security
   - Needs read/write permissions

### Optional Configuration

- **GitHub Container Registry**: Works automatically with `GITHUB_TOKEN` (no additional setup needed)
- **Multi-platform builds**: Currently configured for `linux/amd64` and `linux/arm64`

## Usage

### Automatic Builds

- **On push to main**: Builds and publishes `latest` tag
- **On version tag**: Builds and publishes version tags (e.g., `v1.0.0`, `1.0`, `1`)

### Manual Builds

1. Go to Actions → "Build and Publish Docker Image"
2. Click "Run workflow"
3. Optionally specify a custom tag
4. Click "Run workflow"

### Creating a Release

1. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. The release workflow will automatically:
   - Build and publish the Docker image
   - Generate a changelog
   - Create a GitHub release

## Image Tags

The workflows automatically generate the following tags:

- `latest` - Latest build from main branch
- `main` - Build from main branch
- `v1.0.0` - Exact version tag
- `1.0` - Major.minor version
- `1` - Major version only
- `pr-123` - Pull request builds (not published)

## Pulling Images

### From Docker Hub
```bash
docker pull <DOCKERHUB_USERNAME>/jenkins-agent:latest
```

### From GitHub Container Registry
```bash
docker pull ghcr.io/<GITHUB_USERNAME>/jenkins-agent:latest
```

## Security Features

- **Trivy scanning**: Scans for vulnerabilities in the Docker image
- **Hadolint**: Lints Dockerfile for best practices
- **SARIF uploads**: Security findings appear in GitHub Security tab
- **Build attestations**: Provenance attestations for supply chain security

## Troubleshooting

### Build Failures

1. Check the Actions tab for detailed error messages
2. Verify all required secrets are set
3. Ensure Docker Hub token has correct permissions

### Security Scan Failures

- Critical/High severity vulnerabilities will fail the scan
- Review findings in the GitHub Security tab
- Update base image or dependencies as needed

### Multi-platform Build Issues

- If builds are slow, consider removing `linux/arm64` from platforms
- Ensure Docker Hub account supports multi-platform builds
