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

## Initiating and populating the database

The database data is stored in docker volume `flows_pgdata`,
so that application and data remain decoupled.

```bash
export DBNAME=flows18
export DATA_DIR=... # Required by the makefile
export USERNAME=...

## Init swarm
docker swarm init

## Deploy the containers
docker stack deploy -c docker-compose.yml $DBNAME

## Create the database
### (if psql is available in host machine)

psql -h localhost -U $USERNAME -f scripts/create_db.sql

## Populate the database
make populate

## Extend the database

```

## Shutting down

```bash
## Shutdown the containers
docker stack rm $DBNAME
```
