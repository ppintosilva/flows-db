# The Tyne and Wear 2018 traffic flows database

## Requirements

**Software:**
- docker (increase docker's max disk image size as the default value is likely too low)
- timescaledb-parallel-copy (requires go)
- psql (libpq)
- pipenv

**Docker Images**
- postgres
- timescale/timescaledb:latest-pg11
- adminer

## Environment

- `cp .default_env .env`
- Fill in the blank variables in `.env` and modify existing ones if necessary
- Parse the `.env` file using bash: `export $(egrep -v '^#' .env | xargs)`

## Starting the database

```bash
## Init swarm
docker swarm init

## Deploy the containers
docker stack deploy -c docker-compose.yml $(PGDATABASE)
```

## Populating the database

The database data is stored in the named docker volume `flows_pgdata`,
so that the application and data remain decoupled.

```bash
## Create the database (requires libpq on host, but can be done via docker too)
psql -f scripts/create_tables.sql

## Populate the database
make populate

## Expand
make expand

## Run additional aggregation queries
```

## Shutting down

```bash
## Shutdown the containers
docker stack rm $(PGDATABASE)
```
