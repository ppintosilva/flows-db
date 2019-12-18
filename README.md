# Bringing the Tyne and Wear 2018 traffic flows dataset to TimescaleDB

## Requirements

**Software:**
- docker
- timescaledb-parallel-copy (requires go)
- psql (libpq)

**Docker Images**
- postgres
- timescale/timescaledb:latest-pg11
- adminer

## Files

- `docker-compose.yml` sets up

## Starting the database

```bash
## Init swarm
docker swarm init

## Deploy the containers
docker stack deploy -c docker-compose.yml flows18
```

## Populating the database

The database data is stored in docker volume `flows_pgdata`,
so that application and data remain decoupled.

```bash

# Postgres envir variables
export PGHOST=localhost
export PGUSER=...
export PGPASSWORD=...
# Required to populate the database
export DATA_DIR=...

## Create the database (requires libpq on host, but can be done via docker too)
psql -f scripts/create_db.sql

## Populate the database
make populate

## Run additional aggregation queries

```

## Shutting down

```bash
## Shutdown the containers
docker stack rm flows18
```
