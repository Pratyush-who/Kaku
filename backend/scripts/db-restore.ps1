# scripts/db-restore.ps1
# Restores a SQL backup into the PostgreSQL database

param (
    [string]$BackupFilePath
)

$backupDir = Join-Path $PSScriptRoot "..\docker\backups"

# If no file is provided, pick the most recent one in docker/backups
if (-not $BackupFilePath) {
    if (-not (Test-Path $backupDir)) {
        Write-Host "No backups found in '$backupDir'." -ForegroundColor Red
        exit 1
    }

    $latest = Get-ChildItem -Path $backupDir -Filter "*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-Host "No .sql backup files found in '$backupDir'." -ForegroundColor Red
        exit 1
    }
    $BackupFilePath = $latest.FullName
}

if (-not (Test-Path $BackupFilePath)) {
    Write-Host "Backup file not found: $BackupFilePath" -ForegroundColor Red
    exit 1
}

Write-Host "Restoring database from: $BackupFilePath" -ForegroundColor Cyan
$confirmation = Read-Host "This will overwrite existing data. Are you sure? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Restore cancelled." -ForegroundColor Yellow
    exit 0
}

Get-Content -Path $BackupFilePath -Raw | docker exec -i kaku-postgres psql -U postgres -d kaku

if ($LASTEXITCODE -eq 0) {
    Write-Host "Database successfully restored from backup!" -ForegroundColor Green
} else {
    Write-Host "Failed to restore database. Make sure container 'kaku-postgres' is running." -ForegroundColor Red
}
