CREATE TABLE od_05min
(
  o INTEGER NOT NULL,
  d INTEGER NOT NULL,
  t TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  flow INTEGER,
  median_avspeed NUMERIC,
  mean_avspeed NUMERIC,
  sd_avspeed NUMERIC,
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
SELECT create_hypertable('od_15min'  , 't', chunk_time_interval => interval '2 months');
SELECT create_hypertable('od_1hour'  , 't', chunk_time_interval => interval '4 months');
SELECT create_hypertable('od_24hours', 't', chunk_time_interval => interval '12 months');
SELECT create_hypertable('od_7days'  , 't', chunk_time_interval => interval '12 months');


--- Aggregate tables

CREATE TABLE agg_hour_weekday
(
  o INTEGER NOT NULL,
  d INTEGER NOT NULL,
  hour INTEGER NOT NULL,
  weekday INTEGER NOT NULL,
  sum_flow INTEGER,
  median_flow NUMERIC,
  sum_mean_avspeed NUMERIC,
  median_mean_avspeed NUMERIC,
  sum_sd_avspeed NUMERIC,
  median_sd_avspeed NUMERIC,
  sum_median_avspeed NUMERIC,
  median_median_avspeed NUMERIC,
  PRIMARY KEY(o,d,hour,weekday)
);

CREATE TABLE agg_05min_weekdaycat
(
  o INTEGER NOT NULL,
  d INTEGER NOT NULL,
  period TIME NOT NULL,
  weekdaycat INTEGER NOT NULL,
  sum_flow INTEGER,
  median_flow NUMERIC,
  sum_mean_avspeed NUMERIC,
  median_mean_avspeed NUMERIC,
  sum_sd_avspeed NUMERIC,
  median_sd_avspeed NUMERIC,
  sum_median_avspeed NUMERIC,
  median_median_avspeed NUMERIC,
  PRIMARY KEY(o,d,period,weekdaycat)
);

CREATE TABLE agg_15min_weekdaycat
(
  o INTEGER NOT NULL,
  d INTEGER NOT NULL,
  period TIME NOT NULL,
  weekdaycat INTEGER NOT NULL,
  sum_flow INTEGER,
  median_flow NUMERIC,
  sum_mean_avspeed NUMERIC,
  median_mean_avspeed NUMERIC,
  sum_sd_avspeed NUMERIC,
  median_sd_avspeed NUMERIC,
  sum_median_avspeed NUMERIC,
  median_median_avspeed NUMERIC,
  PRIMARY KEY(o,d,period,weekdaycat)
);

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
