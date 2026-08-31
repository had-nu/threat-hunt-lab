#!/bin/bash
# Threat Hunt Lab - Backup Script
# Usage: ./scripts/backup.sh [backup_dir]

set -euo pipefail

BACKUP_DIR="${1:-./backups/$(date +%F_%H-%M-%S)}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Threat Hunt Lab Backup ==="
echo "Project: $PROJECT_ROOT"
echo "Backup dir: $BACKUP_DIR"
echo ""

mkdir -p "$BACKUP_DIR"

# Check if containers are running
if ! docker compose -f "$PROJECT_ROOT/docker-compose.yml" ps --services --filter "status=running" | grep -q .; then
    echo "⚠️  No containers running. Backing up volumes directly..."
    VOLUMES_RUNNING=false
else
    echo "✓ Containers running. Will backup via containers..."
    VOLUMES_RUNNING=true
fi

# Backup function
backup_volume() {
    local volume_name="$1"
    local output_file="$2"
    echo "  Backing up volume: $volume_name"
    docker run --rm \
        -v "$volume_name":/data:ro \
        -v "$BACKUP_DIR":/backup \
        alpine:latest \
        tar czf "/backup/$output_file" -C /data .
}

echo ""
echo "--- Backing up Docker volumes ---"

# Named volumes (prefixed with threatlab-)
volumes=(
    "threatlab-splunk-data:splunk-data.tar.gz"
    "threatlab-splunk-etc:splunk-etc.tar.gz"
    "threatlab-caldera-logs:caldera-logs.tar.gz"
    "threatlab-caldera-conf:caldera-conf.tar.gz"
    "threatlab-caldera-plugins:caldera-plugins.tar.gz"
)

for vol in "${volumes[@]}"; do
    vol_name="${vol%%:*}"
    vol_file="${vol##*:}"
    if docker volume inspect "$vol_name" >/dev/null 2>&1; then
        backup_volume "$vol_name" "$vol_file"
    else
        echo "  ⚠️  Volume $vol_name not found, skipping"
    fi
done

echo ""
echo "--- Backing up configuration files ---"
cp "$PROJECT_ROOT/.env" "$BACKUP_DIR/.env.bak" 2>/dev/null && echo "  ✓ .env" || echo "  ⚠️  .env not found"
cp "$PROJECT_ROOT/docker-compose.yml" "$BACKUP_DIR/docker-compose.yml.bak" && echo "  ✓ docker-compose.yml"
cp -r "$PROJECT_ROOT/caldera/conf" "$BACKUP_DIR/caldera-conf-files" 2>/dev/null && echo "  ✓ caldera/conf" || echo "  ⚠️  caldera/conf not found"
cp -r "$PROJECT_ROOT/splunk/etc" "$BACKUP_DIR/splunk-etc-files" 2>/dev/null && echo "  ✓ splunk/etc" || echo "  ⚠️  splunk/etc not found"

echo ""
echo "--- Creating manifest ---"
cat > "$BACKUP_DIR/MANIFEST.txt" <<EOF
Threat Hunt Lab Backup
======================
Date: $(date -Iseconds)
Host: $(hostname)
Project: $PROJECT_ROOT

Volumes:
$(for vol in "${volumes[@]}"; do
    vol_name="${vol%%:*}"
    vol_file="${vol##*:}"
    if [ -f "$BACKUP_DIR/$vol_file" ]; then
        size=$(du -h "$BACKUP_DIR/$vol_file" | cut -f1)
        echo "  - $vol_file ($size)"
    fi
done)

Config files:
  - .env.bak
  - docker-compose.yml.bak
  - caldera-conf-files/
  - splunk-etc-files/

Docker images used:
$(docker compose -f "$PROJECT_ROOT/docker-compose.yml" config --images 2>/dev/null || echo "  (compose not available)")

Git commit: $(cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
Git branch: $(cd "$PROJECT_ROOT" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
EOF

echo ""
echo "=== Backup Complete ==="
echo "Location: $BACKUP_DIR"
echo ""
echo "To restore:"
echo "  ./scripts/restore.sh $BACKUP_DIR"
echo ""
du -sh "$BACKUP_DIR"