# Moonin Platform Helm Chart

> A Helm chart for deploying Moonin Platform on Kubernetes.

Chart version: 0.1.3

## Prerequisites

- Kubernetes 1.25 or later.
- Helm 3.15 or later.
- An image pull secret named `ghcr-secret` in the target namespace when private
  Moonin images are used.
- The application secrets referenced by `values.yaml`, including
  `moonin-license`, `db-secret`, and `moonin-front-secret`.

## Install from GHCR

```sh
helm upgrade --install moonin-platform oci://ghcr.io/moonin-lab/moonin-platform --version 0.1.3 --namespace arguz --create-namespace
```

## Install from GitHub Pages

```sh
helm repo add moonin-platform https://moonin-lab.github.io/Moonin-Platform-Chart
helm repo update
helm upgrade --install moonin-platform moonin-platform/moonin-platform --namespace arguz --create-namespace
```

## Configuration

The chart's defaults are in [`values.yaml`](values.yaml). Provide environment-
specific overrides in a separate values file:

```sh
helm upgrade --install moonin-platform oci://ghcr.io/moonin-lab/moonin-platform --version 0.1.3 --namespace arguz --create-namespace --values production-values.yaml
```

The publishing workflow updates the chart version and the OCI install commands
when a version tag is released.
