# The Tyne and Wear 2018 traffic flows database

## Requirements

**Software:**
- docker
- timescaledb-parallel-copy (requires go)
- psql (libpq)
- pipenv

**Docker Images**
- postgres
- timescale/timescaledb:latest-pg11
- adminer

## Environment

- Write down your postgres **username** and **password** on the files `.user` and `.password`, respectively.
- (modify `export_env.sh` if necessary)
- `source export_env.sh`

## Starting the database

```bash
## Init swarm
docker swarm init

## Deploy the containers
docker stack deploy -c docker-compose.yml flows18
```

## Populating the database

The database data is stored in the named docker volume `flows_pgdata`,
so that the application and data remain decoupled.

```bash
## Create the database (requires libpq on host, but can be done via docker too)
psql -f scripts/create_db.sql

## Populate the database
make populate

## Expand
make expand

## Run additional aggregation queries
```

## Shutting down

```bash
## Shutdown the containers
docker stack rm flows18
```
