CREATE DATABASE flows18;

-- Connect to the database
\c flows18;

CREATE TABLE od_05min
(
  o INTEGER NOT NULL,
  d INTEGER NOT NULL,
  t TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  flow INTEGER,
  mean_avspeed NUMERIC,
  sd_avspeed NUMERIC,
  skew_avspeed NUMERIC,
  PRIMARY KEY(o,d,t)
);

-- Duplicate the above table for all different aggregation resolutions
-- NOT NULL constraint on t does not carry on so enforce it

CREATE TABLE od_15min   AS (SELECT * FROM od_05min) WITH NO DATA;
ALTER TABLE od_15min ADD PRIMARY KEY (o,d,t);

CREATE TABLE od_1hour   AS (SELECT * FROM od_05min) WITH NO DATA;
ALTER TABLE od_1hour ADD PRIMARY KEY (o,d,t);

CREATE TABLE od_24hours AS (SELECT * FROM od_05min) WITH NO DATA;
ALTER TABLE od_24hours ADD PRIMARY KEY (o,d,t);

CREATE TABLE od_7days   AS (SELECT * FROM od_05min) WITH NO DATA;
ALTER TABLE od_7days ADD PRIMARY KEY (o,d,t);

CREATE TABLE od_total   AS (SELECT * FROM od_05min) WITH NO DATA;
ALTER TABLE od_total ADD PRIMARY KEY (o,d,t);

-- -- Create hypertables:
-- --   + default chunk_time_interval = 1 week
-- --   + 1 chunk should be able to fit in memory
-- --   + Q1: what is the memory footprint of 1 week of data?
-- --   + Q2: how much memory can my server allocate to the database?

SELECT create_hypertable('od_05min'  , 't', chunk_time_interval => interval '1 month');
SELECT create_hypertable('od_15min'  , 't', chunk_time_interval => interval '1 month');
SELECT create_hypertable('od_1hour'  , 't', chunk_time_interval => interval '1 month');
SELECT create_hypertable('od_24hours', 't', chunk_time_interval => interval '1 month');
SELECT create_hypertable('od_7days'  , 't', chunk_time_interval => interval '1 month');
SELECT create_hypertable('od_total'  , 't', chunk_time_interval => interval '1 month');
