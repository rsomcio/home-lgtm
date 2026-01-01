I need help setting up a complete LGTM (Loki, Grafana, Tempo, Mimir) observability stack for my homelab.

Hardware:
- Raspberry Pi 5 with 8GB RAM
- Storage mounted at /mnt/lgtm with 250GB available

Requirements:
- Run everything in Docker using docker-compose
- Optimize for Pi resource constraints (8GB RAM)
- Use the 250GB storage for persistent data
- Include OTLP receivers for receiving metrics, logs, and traces from other systems
- Configure Grafana with datasources pre-provisioned
- Set reasonable retention periods (30 days)
- Include health monitoring for the stack components themselves

Please provide:
1. Complete docker-compose.yml with resource limits
2. Configuration files for each component (Loki, Tempo, Mimir/Prometheus)
3. Grafana datasource provisioning configuration
4. Directory structure and setup commands
5. Instructions for accessing each service

Note: If Mimir is too heavy for a Pi, suggest using Prometheus instead for metrics.
