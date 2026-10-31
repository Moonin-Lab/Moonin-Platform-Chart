# Moonin Platform Helm Chart

> A Helm chart for deploying Moonin Platform on Kubernetes.

Chart version: 0.1.31

## Prerequisites

- Kubernetes 1.25 or later.
- Helm 3.15 or later.
- An image pull secret named `ghcr-secret` in the target namespace when private
  Moonin images are used.
- The application secrets referenced by `values.yaml`, including
  `moonin-license`, `db-secret`, and `moonin-front-secret`.

## Install from GHCR

```sh
helm upgrade --install moonin-platform oci://ghcr.io/moonin-lab/moonin-platform --version 0.1.31 --namespace arguz --create-namespace
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
helm upgrade --install moonin-platform oci://ghcr.io/moonin-lab/moonin-platform --version 0.1.31 --namespace arguz --create-namespace --values production-values.yaml
```

The publishing workflow updates the chart version and the OCI install commands
when a version tag is released.

## AI Sync Configuration

AI Sync remains a Helm-managed CronJob on the existing `*/30 * * * *`
schedule. By default, `moonin-ai-sync.configSecret.existingSecret` is empty:
the application uses legacy Vertex configuration and its existing ServiceAccount
(`ai-sync`), without requiring a provider configuration Secret. In this mode,
`moonin-ai-sync.aiModel` optionally sets `AI_MODEL`; an empty value leaves the
application's default model unchanged.

For an installer-configured OpenAI-compatible provider, reference only the name
of the existing Secret:

```yaml
moonin-ai-sync:
  configSecret:
    existingSecret: moonin-ai-sync-config
```

The installer must provision that Secret before the job runs, in
`moonin-ai-sync.namespace` (default `moonin`), with these environment keys:

| Secret Key | Contract |
| --- | --- |
| `AI_SYNC_PROVIDER` | Provider identifier accepted by AI Sync. |
| `AI_SYNC_ENDPOINT` | OpenAI-compatible API endpoint. |
| `AI_SYNC_API_KEY` | Provider credential. |
| `AI_MODEL` | Model selected by the installer. |

The chart imports the existing Secret through `envFrom.secretRef`; it does not
create it, inspect its contents, or put provider credentials in Helm values or
rendered manifests. Kubernetes requires the configured Secret to exist.
`moonin-ai-sync.aiModel` is ignored in Secret mode, even if nonempty, so it cannot
override the Secret's `AI_MODEL`. No provider variables are explicitly rendered.
The existing database and license `secretKeyRef` entries, ServiceAccount, job
policy, and schedule are unchanged. Keep this dedicated provider Secret limited
to the four keys above; it is not a replacement for database or license Secrets.

Run the focused render and lint regression tests (Helm and Ruby required):

```sh
ruby tests/ai_sync_render_test.rb
```
