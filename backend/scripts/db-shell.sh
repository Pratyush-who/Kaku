#!/usr/bin/env bash
# scripts/db-shell.sh - Connect to psql interactive shell
docker exec -it kaku-postgres psql -U postgres -d kaku
