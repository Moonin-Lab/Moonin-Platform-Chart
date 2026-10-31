# Moonin Platform Helm Chart

> A Helm chart for deploying Moonin Platform on Kubernetes.

Chart version: 0.1.32

## Prerequisites

- Kubernetes 1.25 or later.
- Helm 3.15 or later.
- An image pull secret named `ghcr-secret` in the target namespace when private
  Moonin images are used.
- The application secrets referenced by `values.yaml`, including
  `moonin-license`, `db-secret`, and `moonin-front-secret`.

## Install from GHCR

```sh
helm upgrade --install moonin-platform oci://ghcr.io/moonin-lab/moonin-platform --version 0.1.32 --namespace arguz --create-namespace
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
helm upgrade --install moonin-platform oci://ghcr.io/moonin-lab/moonin-platform --version 0.1.32 --namespace arguz --create-namespace --values production-values.yaml
```

The publishing workflow updates the chart version and the OCI install commands
when a version tag is released.

## AI Sync Configuration

AI Sync is a Helm-managed CronJob on the existing `*/30 * * * *` schedule and
requires one OpenAI-compatible endpoint for the installation. Vertex is not
supported. The installer prompts for endpoint, model, and API key, then creates
the required Kubernetes Secret before deploying the chart. The CronJob does not
use a dedicated ServiceAccount or mount a Kubernetes service-account token.

The chart references only the name of the existing Secret:

```yaml
moonin-ai-sync:
  configSecret:
    existingSecret: moonin-ai-sync-config
```

The installer must provision that Secret before the job runs, in
`moonin-ai-sync.namespace` (default `moonin`), with these environment keys:

| Secret Key | Contract |
| --- | --- |
| `AI_SYNC_PROVIDER` | Must be `openai-compatible`. |
| `AI_SYNC_ENDPOINT` | OpenAI-compatible API endpoint. |
| `AI_SYNC_API_KEY` | Provider credential. |
| `AI_MODEL` | Model selected by the installer. |

The chart imports the existing Secret through `envFrom.secretRef`; it does not
create it, inspect its contents, or put provider credentials in Helm values or
rendered manifests. The chart schema requires a non-empty Secret reference, and
Kubernetes requires that Secret to exist before the CronJob can start. The
service-account token is not mounted. Keep this dedicated provider Secret limited
to the four keys above; it is not a replacement for database or license Secrets.

Run the focused render and lint regression tests (Helm and Ruby required):

```sh
ruby tests/ai_sync_render_test.rb
```
