CREATE TABLE flows05m
(
  o INTEGER NOT NULL,
  d INTEGER NOT NULL,
  t TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  count INTEGER,
  median_speed NUMERIC,
  mean_speed NUMERIC,
  sd_speed NUMERIC,
  PRIMARY KEY(o,d,t)
);

-- Duplicate the above table for all different aggregation resolutions
-- NOT NULL constraint on t does not carry on so enforce it

CREATE TABLE flows15m   AS (SELECT * FROM flows05m) WITH NO DATA;
ALTER TABLE flows15m ADD PRIMARY KEY (o,d,t);

CREATE TABLE flows1h   AS (SELECT * FROM flows05m) WITH NO DATA;
ALTER TABLE flows1h ADD PRIMARY KEY (o,d,t);

CREATE TABLE flows24h AS (SELECT * FROM flows05m) WITH NO DATA;
ALTER TABLE flows24h ADD PRIMARY KEY (o,d,t);

CREATE TABLE flows7d   AS (SELECT * FROM flows05m) WITH NO DATA;
ALTER TABLE flows7d ADD PRIMARY KEY (o,d,t);

-- -- Create hypertables:
-- --   + default chunk_time_interval = 1 week
-- --   + 1 chunk should be able to fit in memory
-- --   + Q1: what is the memory footprint of 1 week of data?
-- --   + Q2: how much memory can my server allocate to the database?

SELECT create_hypertable('flows05m', 't', chunk_time_interval => interval '1 month');
SELECT create_hypertable('flows15m', 't', chunk_time_interval => interval '2 months');
SELECT create_hypertable('flows1h' , 't', chunk_time_interval => interval '4 months');
SELECT create_hypertable('flows24h', 't', chunk_time_interval => interval '12 months');
SELECT create_hypertable('flows7d' , 't', chunk_time_interval => interval '12 months');

--- Functions

-- median
CREATE OR REPLACE FUNCTION _final_median(NUMERIC[])
   RETURNS NUMERIC AS
$$
   SELECT AVG(val)
   FROM (
     SELECT val
     FROM unnest($1) val
     ORDER BY 1
     LIMIT  2 - MOD(array_upper($1, 1), 2)
     OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
   ) sub;
$$
LANGUAGE 'sql' IMMUTABLE;

CREATE AGGREGATE median(NUMERIC) (
  SFUNC=array_append,
  STYPE=NUMERIC[],
  FINALFUNC=_final_median,
  INITCOND='{}'
);

-- function that takes a day of the week and squashes into weekday/sat/sunday
CREATE FUNCTION dowcat(d INTEGER) RETURNS INTEGER AS
$$
  BEGIN
    IF d = 0 THEN
      RETURN 1;
    ELSIF d = 6 THEN
      RETURN 2;
    ELSE
      RETURN 0;
    END IF;
  END
$$ LANGUAGE plpgsql;
