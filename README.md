# WKID - WorkloadIdentity K8s JWKS Server

A Kubernetes JWKS (JSON Web Key Set) server that simplifies Azure Workload Identity setup for self-managed clusters by replacing the manual OpenID Connect issuer configuration.

## Overview

This project provides a containerized JWKS server that serves public keys for Azure Workload Identity validation in self-managed Kubernetes clusters. It eliminates the need for manual OIDC issuer setup by automating the generation and serving of the required JWKS endpoints.

### What This Replaces

For self-managed Kubernetes clusters, Azure Workload Identity typically requires manual setup of:

1. **Service Account Key Generation** - Creating RSA key pairs for signing service account tokens
2. **OpenID Connect Issuer Setup** - Configuring a public OIDC issuer URL with proper endpoints
3. **Discovery Document** - Creating and hosting the `.well-known/openid-configuration` document
4. **JWKS Endpoint** - Hosting the JSON Web Key Set at `/openid/v1/jwks`
5. **Azure Blob Storage** - Using Azure Storage to serve these documents publicly

**WKID automates this entire process** by providing a ready-to-deploy Kubernetes service that:

- Automatically generates JWKS documents from your service account public keys
- Serves the required OIDC discovery endpoints
- Eliminates the need for external Azure Blob Storage setup
- Provides a secure, self-contained solution running within your cluster

### Built With

This solution is built using the Azure Workload Identity CLI tool (`azwi`) and packaged as both a Docker image and Helm chart for easy deployment.

## Azure Workload Identity Integration

### Prerequisites for Self-Managed Clusters

Before deploying WKID, ensure your self-managed Kubernetes cluster has the required configurations for Azure Workload Identity:

#### 1. Kubernetes API Server Configuration

Configure the following flags in your `kube-apiserver`:

```bash
--service-account-issuer=https://your-cluster-domain.com
--service-account-signing-key-file=/path/to/sa.key
--service-account-key-file=/path/to/sa.pub
```

#### 2. Kubernetes Controller Manager Configuration

Configure the following flag in your `kube-controller-manager`:

```bash
--service-account-private-key-file=/path/to/sa.key
```

#### 3. Feature Flags

Ensure **Service Account Token Volume Projection** is enabled (default in Kubernetes v1.20+).

### OIDC Issuer Endpoints

WKID provides the required OpenID Connect endpoints that Azure AD uses for token validation:

- **Discovery Document**: `{IssuerURL}/.well-known/openid-configuration`
- **JWKS Endpoint**: `{IssuerURL}/openid/v1/jwks`

Where `{IssuerURL}` normally is your cluster's service account issuer URL configured in the `kube-apiserver`, WKID provides a way to make this accessibly by Azure.

### Deployment Benefits

By using WKID instead of the manual Azure Blob Storage approach, you get:

- **Self-contained**: No external dependencies on Azure Storage
- **Automated**: Automatic JWKS generation and serving
- **Secure**: Runs within your cluster's security boundary
- **Scalable**: Kubernetes-native deployment with replica support
- **Maintainable**: Version-controlled configuration and updates

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

### Quick Start with Helm

The easiest way to deploy WKID is using the Helm chart:

```bash
# Install from OCI registry
helm install wkid oci://ghcr.io/toms-place/charts/wkid

# Install with custom values
helm install wkid oci://ghcr.io/toms-place/charts/wkid \
  --set image.tag=v1.0.0 \
  --set replicaCount=3
```

### Docker Image Usage

For standalone or custom deployments:

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

### Verifying the OIDC Endpoints

After deployment, verify that the OIDC endpoints are accessible:

```bash
# Check the discovery document
curl -s "https://your-cluster-domain.com/.well-known/openid-configuration"

# Check the JWKS endpoint
curl -s "https://your-cluster-domain.com/openid/v1/jwks"
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

- `PUBLIC_KEY_PATH`: Path to the public key file (default: `/etc/kubernetes/pki/sa.pub`)
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

## References

For more information about Azure Workload Identity and self-managed cluster setup, refer to the official documentation:

- [Azure Workload Identity for Self-Managed Clusters](https://azure.github.io/azure-workload-identity/docs/installation/self-managed-clusters.html)
- [Service Account Key Generation](https://azure.github.io/azure-workload-identity/docs/installation/self-managed-clusters/service-account-key-generation.html)
- [OpenID Connect Issuer Setup](https://azure.github.io/azure-workload-identity/docs/installation/self-managed-clusters/oidc-issuer.html)
- [Discovery Document Configuration](https://azure.github.io/azure-workload-identity/docs/installation/self-managed-clusters/oidc-issuer/discovery-document.html)
- [JWKS Endpoint Setup](https://azure.github.io/azure-workload-identity/docs/installation/self-managed-clusters/oidc-issuer/jwks.html)
- [Kubernetes Configuration Requirements](https://azure.github.io/azure-workload-identity/docs/installation/self-managed-clusters/configurations.html)

## License

See [LICENSE](LICENSE) file for details.
