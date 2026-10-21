# scripts/db-down.ps1
# Stops the Kaku database containers

Write-Host "Stopping Kaku database containers..." -ForegroundColor Yellow
docker compose down

if ($LASTEXITCODE -eq 0) {
    Write-Host "Kaku database containers stopped cleanly." -ForegroundColor Green
} else {
    Write-Host "Error stopping containers." -ForegroundColor Red
}
