
## Requirements

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

## Initiating the container and populating the database

The database data is stored in docker volume `flows_pgdata`,
so that application and data remain decoupled.

```bash
export DBNAME=flows18
export DATA_DIR=... # FILL THIS VALUE!!
export USER=...

## Init swarm
docker swarm init

## Deploy the containers
docker stack deploy -c docker-compose.yml $DBNAME

## Create the database
### (if psql is available in host machine)

psql -h localhost -U admin123 -f scripts/create_db.sql

## Populate the database
make populate

## Extend the database

```

## Shutting down

```bash
## Shutdown the containers
docker stack rm flows18
```
