# scripts/db-shell.ps1
# Opens an interactive psql shell inside the running PostgreSQL container

Write-Host "Opening interactive psql shell for database 'kaku'..." -ForegroundColor Cyan
docker exec -it kaku-postgres psql -U postgres -d kaku
