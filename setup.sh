#!/bin/bash
# LGTM Stack Setup Script for Raspberry Pi 5

set -e

echo "=== LGTM Stack Setup for Raspberry Pi 5 ==="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./setup.sh"
    exit 1
fi

# Create data directories on mounted storage
echo "Creating data directories on /mnt/lgtm..."
mkdir -p /mnt/lgtm/{grafana,prometheus,loki,tempo}

# Set appropriate ownership (Grafana runs as user 472)
chown -R 472:472 /mnt/lgtm/grafana

# Prometheus and others run as nobody (65534)
chown -R 65534:65534 /mnt/lgtm/prometheus
chown -R 10001:10001 /mnt/lgtm/loki
chown -R 10001:10001 /mnt/lgtm/tempo

echo "Data directories created."
echo ""

# Check available disk space
echo "Checking disk space on /mnt/lgtm..."
df -h /mnt/lgtm
echo ""

# Verify Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first:"
    echo "  curl -fsSL https://get.docker.com | sh"
    echo "  sudo usermod -aG docker \$USER"
    exit 1
fi

echo "Docker version: $(docker --version)"
echo ""

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "Docker Compose is not available. Please install Docker Compose plugin."
    exit 1
fi

echo "Docker Compose version: $(docker compose version)"
echo ""

# Pull images first to track progress
echo "Pulling Docker images (this may take a while on Pi)..."
docker compose pull

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To start the stack:"
echo "  docker compose up -d"
echo ""
echo "To view logs:"
echo "  docker compose logs -f"
echo ""
echo "To stop the stack:"
echo "  docker compose down"
echo ""
