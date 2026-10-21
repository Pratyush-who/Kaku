.PHONY: db-up db-down db-shell db-logs db-reset db-backup db-restore run test

# Start PostgreSQL and web UI (pgweb)
db-up:
	docker compose up -d

# Stop PostgreSQL and web UI
db-down:
	docker compose down

# Open interactive psql shell
db-shell:
	docker exec -it kaku-postgres psql -U postgres -d kaku

# View PostgreSQL logs
db-logs:
	docker compose logs -f postgres

# Create a full SQL backup in docker/backups/
db-backup:
	./scripts/db-backup.sh

# Restore from the latest backup in docker/backups/
db-restore:
	./scripts/db-restore.sh

# Reset database (deletes volume and recreates schema)
db-reset:
	docker compose down -v
	docker compose up -d

# Run the Go backend server
run:
	go run main.go

# Run unit and integration tests
test:
	go test -v ./...
