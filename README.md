# WKID - WorkloadIdentity K8s JWKS Server

A Kubernetes JWKS (JSON Web Key Set) server for Azure Workload Identity.

## Overview

This project provides a containerized JWKS server that serves public keys for Azure Workload Identity validation. It's built using the Azure Workload Identity CLI tool (`azwi`) and packaged as both a Docker image and Helm chart.

## CI/CD Workflows

This repository includes three GitHub Actions workflows:

### 1. Build and Publish (`build-and-publish.yml`)

**Triggers:**

- Push to `main` branch
- Push of version tags (`v*`)
- Pull requests to `main`

**Jobs:**

- **build-and-push-image**: Builds and pushes Docker images to GitHub Container Registry
- **publish-helm-chart**: Packages and publishes Helm charts to OCI registry (only on main/tags)
- **security-scan**: Runs Trivy vulnerability scanning on built images

**Outputs:**

- Docker images: `ghcr.io/toms-place/wkid:<tag>`
- Helm charts: `oci://ghcr.io/toms-place/charts/wkid`

### 2. PR Validation (`pr-validation.yml`)

**Triggers:**

- Pull requests to `main` branch

**Jobs:**

- **validate-dockerfile**: Lints Dockerfile with Hadolint
- **validate-helm**: Lints and validates Helm chart templates
- **test-build**: Test builds Docker image without pushing

### 3. Release (`release.yml`)

**Triggers:**

- Push of version tags (`v*`)

**Jobs:**

- **release**: Creates GitHub releases with changelog and usage instructions

## Usage

### Docker Image

```bash
# Pull the latest image
docker pull ghcr.io/toms-place/wkid:main

# Run with custom parameters
docker run -d \
  -p 8080:8080 \
  -v /path/to/sa.pub:/etc/kubernetes/pki/sa.pub:ro \
  -v /path/to/output:/web \
  ghcr.io/toms-place/wkid:main \
  jwks --public-keys /etc/kubernetes/pki/sa.pub --output-file /web/jwks.json
```

### Helm Chart

```bash
# Install from OCI registry
helm install wkid oci://ghcr.io/toms-place/charts/wkid

# Install with custom values
helm install wkid oci://ghcr.io/toms-place/charts/wkid \
  --set image.tag=v1.0.0 \
  --set replicaCount=3
```

## Development

### Prerequisites

- Docker
- Helm 3.x
- kubectl (for testing deployments)

### Local Development

1. Build the Docker image:

   ```bash
   docker build -t wkid:dev .
   ```

2. Test the Helm chart:

   ```bash
   helm lint chart/
   helm template wkid chart/ --debug
   ```

3. Install locally:

   ```bash
   helm install wkid chart/ --set image.tag=dev
   ```

### Versioning

- **Main branch**: Creates images tagged with `main-<sha>`
- **Version tags**: Creates images and charts with semantic versions (e.g., `v1.2.3`)
- **Pull requests**: Creates test images tagged with `pr-<number>-<sha>`

### Configuration

The application supports the following environment variables:

- `PUBLIC_KEY`: Path to the public key file (default: `/etc/kubernetes/pki/sa.pub`)
- `OUTPUT_FILE`: Path to output JWKS file (default: `/web/jwks.json`)
- `ADDITIONAL_FLAGS`: Additional flags for the azwi command

## Security

- Images are scanned with Trivy for vulnerabilities
- Built using distroless base images for minimal attack surface
- Runs as non-root user (UID 65532)
- Uses multi-stage builds to reduce image size

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure tests pass (`helm lint chart/`)
5. Submit a pull request

The PR validation workflow will automatically check your changes.

## License

See [LICENSE](LICENSE) file for details.
