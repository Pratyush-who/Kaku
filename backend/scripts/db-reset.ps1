# scripts/db-reset.ps1
# Resets the database by destroying the volume and re-initializing from schema

$confirmation = Read-Host "Are you sure you want to completely RESET the database and erase all local data? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Reset cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "Tearing down database and deleting volume..." -ForegroundColor Yellow
docker compose down -v

Write-Host "Re-starting fresh database..." -ForegroundColor Cyan
docker compose up -d

Write-Host "Database reset complete. All initial tables recreated." -ForegroundColor Green
