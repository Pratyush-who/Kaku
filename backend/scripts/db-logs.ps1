# scripts/db-logs.ps1
# Follows PostgreSQL container logs

Write-Host "Streaming logs for 'kaku-postgres' (Ctrl+C to exit)..." -ForegroundColor Cyan
docker compose logs -f postgres
