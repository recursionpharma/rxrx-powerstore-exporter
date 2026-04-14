# PowerStore Metrics Exporter - Recursion Custom Build

This is Recursion Pharmaceuticals' fork of [dell/powerstore-metrics-exporter](https://github.com/dell/powerstore-metrics-exporter) with custom modifications for k8s-dc cluster monitoring.

## Quick Start

### Pull the Image
```bash
docker pull us-central1-docker.pkg.dev/eng-ops-b1bb36c9/container-images/rxrx-powerstore-exporter:v2-no-wear-metrics
```

### Custom Changes
See [RECURSION_CHANGES.md](./RECURSION_CHANGES.md) for detailed documentation of our modifications.

**Key changes:**
- ✅ Disabled WearMetricCollector (prevents timeouts and auth churn)
- ✅ Fixed config path for Kubernetes secret mounting
- ✅ Optimized for apiLimit: 10 to prevent PowerStore API overwhelm

## Deployment

Deployed via ArgoCD in eng-infrastructure repo:
- Path: `argo/on-prem/k8s-dc/hpc/monitoring/powerstore-exporter/`
- Monitors: PowerStore at `powerstore.dc.rxrx.io`
- Metrics interval: 5 minutes

## Building

```bash
# Build binary for linux/amd64
GOOS=linux GOARCH=amd64 go build -o ./build/powerstore-metrics-exporter

# Build and push Docker image
docker buildx build --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/eng-ops-b1bb36c9/container-images/rxrx-powerstore-exporter:v2-no-wear-metrics \
  --push .
```

## Original Documentation

For general PowerStore exporter documentation, see the [upstream Dell repository](https://github.com/dell/powerstore-metrics-exporter).

## Support

This is a custom build for Recursion Pharmaceuticals internal use. For issues, contact the eng-infrastructure team.
