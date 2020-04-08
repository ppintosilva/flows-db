# The Tyne and Wear 2018 traffic flows database

## Steps

1. Edit and set your environment
2. Start the containers
3. Restore the database from a backup or populate it using csv files
4. Query with psql or a database interface
(see our R package [anprflows](https://github.com/ppintosilva/anprflows)
which uses [dbplyr](https://dbplyr.tidyverse.org/))
5. Shutdown the containers

## Requirements

**Software:**
- docker (increase docker's max disk image size for datasets at higher temporal resolution)
- timescaledb-parallel-copy (requires go)
- psql (libpq)
- pipenv (optional)

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
docker stack deploy -c docker-compose.yml $PGDATABASE
```

## Restoring the database from a backup

First, assuming the environment is correctly set,
connect to the database via the terminal: `psql`

Then run the following commands, replacing `DUMP_FILENAME.bak` by the
appropriate backup filename (e.g. flows18.bak).

```sql
CREATE EXTENSION timescaledb;
SELECT timescaledb_pre_restore();

-- execute the restore (or from a shell)
\! pg_restore -Fc -d $PGDATABASE DUMP_FILENAME.bak


SELECT timescaledb_post_restore();
```

## Populating the database

The database data is stored in the named docker volume `flows_pgdata`,
so that the application and data remain decoupled.

The first sql script creates the following tables:

- flows05m
- flows15m
- flows1h
- flows24h
- flows7d

Then use the second command to populate one of these tables with all
csv files inside a directory.

```bash
## Create the database (requires libpq on host, but can be done via docker too)
psql -f scripts/create_tables.sql

## Populate a table PGTABLE in the database with all csv files under DATA_DIR
make DATA_DIR=data/flows/hourly PGTABLE=flows1h populate

## Repeat for other tables
# make DATA_DIR=data/flows/fivemin PGTABLE=flows5min populate
# make DATA_DIR=data/flows/fifteen PGTABLE=flows15m populate
# make DATA_DIR=data/flows/daily   PGTABLE=flows24h populate
# make DATA_DIR=data/flows/weekly  PGTABLE=flows7d populate
```

You may instead create and your own tables and populate them in a similar way.

## Inspecting the database

The container stack inclues an adminer instance on [localhost:8080] which
can be used to browse the database through a GUI instead of the terminal.

## Shutting down

```bash
## Shutdown the containers
docker stack rm $PGDATABASE
```

## Creating a backup of the database

```bash
pg_dump -Fc -f DUMP_FILENAME.bak $PGDATABASE
```

## Note on missing data (zero counts)

Zero counts are *implicit* to minimise disk space: there are missing
combinations of (origin, destination, time period).
Zero flow counts arise during the night time period, sensor failures or
periods of severe congestion conditions in which cameras fail to capture
number plates.

We suggest that zero counts should only be made *explicit* when working with
a subset of the data, for instance a few weeks, or a small subset of all
od pairs. This can be done via the
[anprflows](https://github.com/ppintosilva/anprflows) R package.

In some versions of the dataset, spurious ods have been removed.
In those cases, it may be okay to make missing data explicit directly in the
database, as there will be a much smaller number of ods and less missing data.

Use `expand_rows.j2` to do that:

```bash
# install j2cli via pip
pipenv install

# activate virtualenv
pipenv shell

# generating the query for example table "flows1h" using template
printf '{"table":"flows1h","frequency":"1 hour"}' | \
j2 --format=json scripts/expand_rows.j2 > scripts/expand_flows1h.sql

# run the query
psql -f scripts/expand_flows1h.sql
```
