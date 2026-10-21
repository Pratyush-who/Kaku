# scripts/db-backup.ps1
# Dumps the PostgreSQL database into docker/backups/

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $PSScriptRoot "..\docker\backups"
$backupFile = Join-Path $backupDir "kaku_backup_$timestamp.sql"

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

Write-Host "Creating backup of 'kaku' database..." -ForegroundColor Cyan

# Run pg_dump inside the container
docker exec -t kaku-postgres pg_dump -U postgres --clean --if-exists kaku | Out-File -FilePath $backupFile -Encoding utf8

if ($LASTEXITCODE -eq 0 -and (Test-Path $backupFile)) {
    $fileSize = (Get-Item $backupFile).Length
    Write-Host "Backup created successfully!" -ForegroundColor Green
    Write-Host "File: $backupFile" -ForegroundColor Gray
    Write-Host "Size: $fileSize bytes" -ForegroundColor Gray
} else {
    Write-Host "Failed to create backup. Make sure the 'kaku-postgres' container is running." -ForegroundColor Red
}
