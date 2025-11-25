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

## Usage

### Quick Start with Helm

The easiest way to deploy WKID is using the Helm chart:

```bash
# Install from OCI registry
helm upgrade --namespace wkid --install wkid oci://ghcr.io/toms-place/charts/wkid \
   --set ingress.enabled=true
   --set ingress.hosts[0].host=your-cluster-domain.com
   --set ingress.tls[0].hosts[0]=your-cluster-domain.com
   --set ingress.tls[0].secretName=wkid-tls-secret
```

### Verifying the OIDC Endpoints

After deployment, verify that the OIDC endpoints are accessible:

```bash
# Check the discovery document
curl -s "https://your-cluster-domain.com/.well-known/openid-configuration"

# Check the JWKS endpoint
curl -s "https://your-cluster-domain.com/openid/v1/jwks"
```

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
