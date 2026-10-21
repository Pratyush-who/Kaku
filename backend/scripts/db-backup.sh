#!/usr/bin/env bash
# scripts/db-backup.sh - Dumps the database into docker/backups/
set -e
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$(dirname "$0")/../docker/backups"
BACKUP_FILE="${BACKUP_DIR}/kaku_backup_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"
echo "Creating backup of 'kaku' database..."
docker exec -t kaku-postgres pg_dump -U postgres --clean --if-exists kaku > "$BACKUP_FILE"
echo "Backup created at $BACKUP_FILE"
