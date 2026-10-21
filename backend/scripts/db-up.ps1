# scripts/db-up.ps1
# Starts PostgreSQL (and pgweb browser) using Docker Compose

Write-Host "Checking Docker status..." -ForegroundColor Cyan

# Test if Docker daemon is running
docker info >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker daemon is not running. Attempting to start Docker Desktop..." -ForegroundColor Yellow
    $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerDesktopPath) {
        Start-Process $dockerDesktopPath
        Write-Host "Waiting for Docker Desktop engine to start (this may take up to 30-45 seconds)..." -ForegroundColor Yellow
        $ready = $false
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 2
            docker info >$null 2>&1
            if ($LASTEXITCODE -eq 0) {
                $ready = $true
                break
            }
        }
        if (-not $ready) {
            Write-Host "Docker is taking longer to start. Please ensure Docker Desktop is open and running, then re-run this script." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Docker Desktop executable not found at '$dockerDesktopPath'. Please launch Docker Desktop manually." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Starting Kaku database services via Docker Compose..." -ForegroundColor Cyan
docker compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n===============================================" -ForegroundColor Green
    Write-Host " Database containers started successfully!" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "PostgreSQL Database:" -ForegroundColor White
    Write-Host "  Host:      localhost" -ForegroundColor Gray
    Write-Host "  Port:      5432" -ForegroundColor Gray
    Write-Host "  Database:  kaku" -ForegroundColor Gray
    Write-Host "  User:      postgres" -ForegroundColor Gray
    Write-Host "  Password:  postgres" -ForegroundColor Gray
    Write-Host "  Conn URL:  postgres://postgres:postgres@localhost:5432/kaku?sslmode=disable" -ForegroundColor Gray
    Write-Host "`nWeb Database Browser (pgweb):" -ForegroundColor White
    Write-Host "  URL:       http://localhost:8081" -ForegroundColor Cyan
    Write-Host "  (No pgAdmin installation needed - preconnected in browser!)" -ForegroundColor DarkGray
    Write-Host "===============================================`n" -ForegroundColor Green
} else {
    Write-Host "Failed to start database containers." -ForegroundColor Red
    exit 1
}
