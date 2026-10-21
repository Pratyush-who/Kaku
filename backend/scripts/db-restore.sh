#!/usr/bin/env bash
# scripts/db-restore.sh - Restores the database from a backup file
set -e
BACKUP_DIR="$(dirname "$0")/../docker/backups"
BACKUP_FILE="${1:-$(ls -t "$BACKUP_DIR"/*.sql 2>/dev/null | head -n 1)}"

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "No backup file found in $BACKUP_DIR"
    exit 1
fi

echo "Restoring database from: $BACKUP_FILE"
docker exec -i kaku-postgres psql -U postgres -d kaku < "$BACKUP_FILE"
echo "Database restored successfully."
