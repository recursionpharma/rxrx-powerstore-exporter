# Recursion Pharmaceuticals Custom Changes

This is a fork of [dell/powerstore-metrics-exporter](https://github.com/dell/powerstore-metrics-exporter) with modifications for Recursion's k8s-dc cluster.

## Custom Image
- **Registry**: `us-central1-docker.pkg.dev/eng-ops-b1bb36c9/container-images/rxrx-powerstore-exporter`
- **Tag**: `v2-no-wear-metrics`
- **Platform**: `linux/amd64`

## Changes from Upstream

### 1. Disabled WearMetricCollector (`route/route.go:120`)

**Problem**: The WearMetricCollector spawns 16 concurrent goroutines to collect drive endurance metrics via `/api/rest/metrics/generate`. Each request takes 60+ seconds and times out, causing:
- 960+ seconds of timeouts per collection cycle
- Hundreds of authentication token relogins per minute
- Eventual panic: `runtime error: index out of range [-1]`

**Solution**: Commented out WearMetricCollector registration:
```go
// Disabled: WearMetricCollector causes timeouts and auth churn
// HardwareRegistry.MustRegister(generalCollector.NewWearMetricCollector(client, bc, logger))
```

**Impact**: 
- No drive endurance percentage metrics
- Stable operation with only 2-4 relogins during startup
- All other metrics collect successfully

### 2. Added Defensive Nil Checks in Hardware Collector (`collector/generalCollector/hardware.go`)

**Problem**: When authentication fails or API rate limiting occurs during initialization, the `PowerstoreModuleID` map isn't fully populated with appliance data. The hardware collector then tries to access nil metric descriptors, causing a panic:
```
panic: runtime error: invalid memory address or nil pointer dereference
at powerstore-metrics-exporter/collector/generalCollector/hardware.go:75
```

**Solution**: Added defensive nil checks before using metric descriptors:
```go
metricDesc := c.metrics["node"+id]
if metricDesc == nil {
    level.Warn(c.logger).Log("msg", "metric descriptor not found for node", "appliance_id", id, "name", nodeName)
    continue
}
ch <- prometheus.MustNewConstMetric(metricDesc, ...)
```

**Impact**:
- Prevents crash-loop when authentication or initialization fails
- Logs warnings about missing metrics instead of panicking
- Allows exporter to continue collecting other available metrics
- Makes the exporter resilient to transient API failures

### 3. Fixed Dockerfile Config Path

**Problem**: Kubernetes mounts secrets as directories with files inside. The original Dockerfile expected config at `/powerstore_exporter/config.yml` but K8s mounts it at `/powerstore_exporter/config/config.yml`.

**Solution**: Updated Dockerfile CMD:
```dockerfile
CMD ["-c","/powerstore_exporter/config/config.yml"]
```

### 4. Build Configuration

Built with:
```bash
GOOS=linux GOARCH=amd64 go build -o ./build/powerstore-metrics-exporter
docker buildx build --platform linux/amd64 -t <image> --push .
```

## Deployment Configuration

### apiLimit Setting
Reduced from default 5000 to **10** in config.yml to prevent API overwhelm:
```yaml
storageList:
  - ip: powerstore.dc.rxrx.io
    apiLimit: 10
```

### ServiceMonitors (5m interval)
- appliance
- capacity
- hardware
- volume
- volumegroup
- port
- nas
- file

### Alerts
See `eng-infrastructure/argo/on-prem/k8s-dc/hpc/monitoring/alertmanager/rules/powerstore-alerts-manifest.yaml`:
- Capacity warnings (>70%, >80%, >90%)
- Hardware health (node, drive, power supply, fan, battery)
- Exporter availability

## Production Metrics
Deployed to k8s-dc cluster monitoring PowerStore at `powerstore.dc.rxrx.io`:
- Pod uptime: Stable with 0 crashes
- Auth relogins: 2-4 during startup only
- All metrics endpoints: Collecting successfully
- Prometheus targets: All up and healthy

## Maintenance Notes

**Do not re-enable WearMetricCollector** - it fundamentally conflicts with PowerStore API rate limits and timeout behavior. If drive endurance metrics are needed in the future, consider:
1. Sequential collection instead of concurrent
2. Longer timeout configuration in the exporter
3. Separate dedicated exporter for wear metrics only
