#!/usr/bin/env bash
# scripts/db-up.sh - Start Docker DB services

set -e
echo "Starting Kaku database services via Docker Compose..."
docker compose up -d

echo ""
echo "==============================================="
echo " Database containers started successfully!"
echo "==============================================="
echo "PostgreSQL: localhost:5432 (DB: kaku, User: postgres)"
echo "Web UI (pgweb): http://localhost:8081"
echo "==============================================="
