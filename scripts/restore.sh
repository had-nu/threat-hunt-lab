#!/bin/bash
# Threat Hunt Lab - Restore Script
# Usage: ./scripts/restore.sh <backup_dir>

set -euo pipefail

BACKUP_DIR="${1:-}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup_directory>"
    echo ""
    echo "Available backups:"
    ls -1d "$PROJECT_ROOT/backups/"*/ 2>/dev/null | head -10 || echo "  No backups found"
    exit 1
fi

echo "=== Threat Hunt Lab Restore ==="
echo "Project: $PROJECT_ROOT"
echo "Backup dir: $BACKUP_DIR"
echo ""

# Confirm
read -p "[AVISO] This will OVERWRITE current volumes and configs. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Stop containers
echo ""
echo "--- Stopping containers ---"
docker compose -f "$PROJECT_ROOT/docker-compose.yml" down

# Restore volumes
echo ""
echo "--- Restoring Docker volumes ---"
if [ -f "$BACKUP_DIR/MANIFEST.txt" ]; then
    echo "Found manifest:"
    cat "$BACKUP_DIR/MANIFEST.txt"
fi

restore_volume() {
    local volume_name="$1"
    local backup_file="$2"
    if [ -f "$backup_file" ]; then
        echo "  Restoring $volume_name from $(basename "$backup_file")"
        docker volume rm "$volume_name" 2>/dev/null || true
        docker volume create "$volume_name" >/dev/null
        docker run --rm \
            -v "$volume_name":/data \
            -v "$(dirname "$backup_file")":/backup:ro \
            alpine:latest \
            tar xzf "/backup/$(basename "$backup_file")" -C /data
    else
        echo "  [AVISO] Backup file not found: $backup_file"
    fi
}

volumes=(
    "threatlab-splunk-data:$BACKUP_DIR/splunk-data.tar.gz"
    "threatlab-splunk-etc:$BACKUP_DIR/splunk-etc.tar.gz"
    "threatlab-caldera-logs:$BACKUP_DIR/caldera-logs.tar.gz"
    "threatlab-caldera-conf:$BACKUP_DIR/caldera-conf.tar.gz"
    "threatlab-caldera-plugins:$BACKUP_DIR/caldera-plugins.tar.gz"
)

for vol in "${volumes[@]}"; do
    vol_name="${vol%%:*}"
    vol_file="${vol##*:}"
    restore_volume "$vol_name" "$vol_file"
done

# Restore config files
echo ""
echo "--- Restoring configuration files ---"
if [ -f "$BACKUP_DIR/.env.bak" ]; then
    cp "$BACKUP_DIR/.env.bak" "$PROJECT_ROOT/.env"
    echo "  [OK] .env restored"
fi

if [ -d "$BACKUP_DIR/caldera-conf-files" ]; then
    rm -rf "$PROJECT_ROOT/caldera/conf"
    cp -r "$BACKUP_DIR/caldera-conf-files" "$PROJECT_ROOT/caldera/conf"
    echo "  [OK] caldera/conf restored"
fi

if [ -d "$BACKUP_DIR/splunk-etc-files" ]; then
    rm -rf "$PROJECT_ROOT/splunk/etc"
    cp -r "$BACKUP_DIR/splunk-etc-files" "$PROJECT_ROOT/splunk/etc"
    echo "  [OK] splunk/etc restored"
fi

# Start containers
echo ""
echo "--- Starting containers ---"
docker compose -f "$PROJECT_ROOT/docker-compose.yml" up -d

echo ""
echo "=== Restore Complete ==="
echo "Containers starting... Check status with: docker compose ps"
echo "Logs: docker compose logs -f"