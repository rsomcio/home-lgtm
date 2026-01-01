# Home LGTM Stack

A complete observability stack for Raspberry Pi 5 homelab environments, featuring Loki (logs), Grafana (visualization), Tempo (traces), and Prometheus (metrics).

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         External Systems                             │
│              (Apps, Services, IoT devices, etc.)                     │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    OpenTelemetry Collector                           │
│                    (Unified OTLP Ingestion)                          │
│                    Ports: 4316 (gRPC), 4319 (HTTP)                   │
└─────────┬─────────────────┬─────────────────┬───────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────┐ ┌───────────────┐ ┌───────────────┐
│   Prometheus    │ │     Loki      │ │     Tempo     │
│    (Metrics)    │ │    (Logs)     │ │   (Traces)    │
│   Port: 9090    │ │  Port: 3100   │ │  Port: 3200   │
└────────┬────────┘ └───────┬───────┘ └───────┬───────┘
         │                  │                 │
         └──────────────────┼─────────────────┘
                            ▼
                   ┌─────────────────┐
                   │     Grafana     │
                   │  (Dashboards)   │
                   │   Port: 3000    │
                   └─────────────────┘
```

## Requirements

- Raspberry Pi 5 with 8GB RAM
- Docker and Docker Compose
- Storage mounted at `/mnt/lgtm` (250GB recommended)
- Network connectivity for external systems

## Quick Start

```bash
# 1. Clone or copy files to your Pi
cd /path/to/home-lgtm

# 2. Run setup script (creates directories and sets permissions)
sudo ./setup.sh

# 3. Start the stack
docker compose up -d

# 4. Access Grafana
open http://<pi-ip>:3000
# Login: admin / admin
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| Grafana | 3000 | Visualization and dashboards |
| Prometheus | 9090 | Metrics storage and querying |
| Loki | 3100 | Log aggregation |
| Tempo | 3200 | Distributed tracing |
| OTEL Collector | 4316, 4319 | Unified telemetry ingestion |
| Promtail | - | Local log shipping |

## Resource Allocation

Optimized for Raspberry Pi 5 with 8GB RAM:

| Service | Memory Limit | Memory Reserved |
|---------|-------------|-----------------|
| Grafana | 512 MB | 256 MB |
| Prometheus | 1.5 GB | 512 MB |
| Loki | 1 GB | 256 MB |
| Tempo | 1 GB | 256 MB |
| OTEL Collector | 512 MB | 128 MB |
| Promtail | 256 MB | 64 MB |
| **Total** | **~4.8 GB** | **~1.5 GB** |

## Data Retention

All components are configured with 30-day retention:

- **Prometheus**: 30 days or 50GB (whichever comes first)
- **Loki**: 30 days
- **Tempo**: 30 days

## Sending Telemetry Data

### From Applications Using OTLP

Configure your applications to send telemetry to the OTEL Collector:

```yaml
# Example: OpenTelemetry SDK configuration
OTEL_EXPORTER_OTLP_ENDPOINT: "http://<pi-ip>:4316"  # gRPC
# or
OTEL_EXPORTER_OTLP_ENDPOINT: "http://<pi-ip>:4319"  # HTTP
```

### Direct to Tempo (Traces Only)

```yaml
OTEL_EXPORTER_OTLP_ENDPOINT: "http://<pi-ip>:4317"  # gRPC
# or
OTEL_EXPORTER_OTLP_ENDPOINT: "http://<pi-ip>:4318"  # HTTP
```

### Pushing Logs to Loki

Using curl:
```bash
curl -X POST "http://<pi-ip>:3100/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [{
      "stream": { "job": "myapp", "level": "info" },
      "values": [["'$(date +%s)000000000'", "Hello from my app!"]]
    }]
  }'
```

Using Promtail on another host:
```yaml
clients:
  - url: http://<pi-ip>:3100/loki/api/v1/push
```

### Prometheus Remote Write

Configure other Prometheus instances to remote write:
```yaml
remote_write:
  - url: http://<pi-ip>:9090/api/v1/write
```

### Prometheus Scraping

Add targets to `prometheus/prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['<service-ip>:8080']
```

Then reload Prometheus:
```bash
curl -X POST http://localhost:9090/-/reload
```

## File Structure

```
home-lgtm/
├── docker-compose.yml          # Main compose file
├── setup.sh                    # Initial setup script
├── README.md                   # This file
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── datasources.yml # Pre-configured datasources
│       └── dashboards/
│           └── dashboards.yml  # Dashboard provisioning
├── loki/
│   └── loki-config.yml         # Loki configuration
├── tempo/
│   └── tempo-config.yml        # Tempo configuration
├── prometheus/
│   └── prometheus.yml          # Prometheus configuration
├── otel-collector/
│   └── config.yml              # OTEL Collector configuration
└── promtail/
    └── promtail-config.yml     # Promtail configuration
```

## Storage Layout

Data is persisted to `/mnt/lgtm`:

```
/mnt/lgtm/
├── grafana/      # Grafana data, plugins, dashboards
├── prometheus/   # Prometheus TSDB
├── loki/         # Loki chunks and index
└── tempo/        # Tempo blocks and WAL
```

## Grafana Features

### Pre-configured Datasources

All datasources are automatically provisioned with correlation enabled:

- **Prometheus** (default) - Metrics with exemplar links to Tempo
- **Loki** - Logs with trace ID extraction linking to Tempo
- **Tempo** - Traces with links to logs and metrics

### Trace-Log-Metric Correlation

The stack is configured for full observability correlation:

1. **Traces → Logs**: Click on a trace to see related logs
2. **Traces → Metrics**: View request rate and error metrics from traces
3. **Logs → Traces**: Extract trace IDs from logs to jump to traces
4. **Metrics → Traces**: Follow exemplars from metrics to traces

## Common Operations

### Start/Stop

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a specific service
docker compose restart loki
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f tempo

# Last 100 lines
docker compose logs --tail=100 prometheus
```

### Check Health

```bash
# All containers status
docker compose ps

# Health endpoints
curl -s http://localhost:3000/api/health      # Grafana
curl -s http://localhost:9090/-/healthy       # Prometheus
curl -s http://localhost:3100/ready           # Loki
curl -s http://localhost:3200/ready           # Tempo
curl -s http://localhost:13133/health         # OTEL Collector
```

### Update Images

```bash
docker compose pull
docker compose up -d
```

### Backup Data

```bash
# Stop services first for consistent backup
docker compose down

# Backup
sudo tar -czvf lgtm-backup-$(date +%Y%m%d).tar.gz /mnt/lgtm

# Restart
docker compose up -d
```

## Troubleshooting

### High Memory Usage

If the Pi becomes unresponsive, reduce memory limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 768M  # Reduce from 1024M
```

### Loki Not Ready

Loki may take 60+ seconds to start. Check logs:
```bash
docker compose logs loki
```

### No Data in Grafana

1. Verify services are healthy: `docker compose ps`
2. Check datasource connectivity in Grafana UI
3. Verify data is being received:
   ```bash
   # Check Prometheus targets
   curl http://localhost:9090/api/v1/targets

   # Check Loki labels
   curl http://localhost:3100/loki/api/v1/labels
   ```

### Permission Errors

Re-run the setup script:
```bash
sudo ./setup.sh
```

### Disk Space

Monitor storage usage:
```bash
df -h /mnt/lgtm
du -sh /mnt/lgtm/*
```

## Performance Tuning

### For Lower Memory Usage

Edit component configs to reduce cache sizes and batch sizes.

### For Higher Throughput

Increase memory limits if you have headroom, and adjust:
- Prometheus: `--storage.tsdb.wal-compression`
- Loki: Increase `ingestion_rate_mb`
- Tempo: Increase `max_block_duration`

## Security Considerations

This setup is intended for homelab use and includes minimal security:

- Grafana default credentials: `admin/admin` (change after first login)
- No TLS configured (add reverse proxy for external access)
- No authentication on Prometheus, Loki, or Tempo APIs

For external access, consider:
1. Setting up a reverse proxy (Traefik, Caddy, nginx)
2. Enabling TLS
3. Adding authentication

## License

MIT
