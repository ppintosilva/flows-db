INSERT INTO
  agg_hour_weekday (
    o,d,hour,weekday,sum_flow,median_flow,
    sum_mean_avspeed,median_mean_avspeed,
    sum_sd_avspeed, median_sd_avspeed,
    sum_median_avspeed, median_median_avspeed)
(
  SELECT
      o
    , d
    , EXTRACT(hour FROM t)   AS hour
    , EXTRACT(dow  FROM t)   AS weekday
    , sum(flow)              AS sum_flow
    , median(flow)           AS median_flow
    , sum(mean_avspeed)      AS sum_mean_avspeed
    , median(mean_avspeed)   AS median_mean_avspeed
    , sum(sd_avspeed)        AS sum_sd_avspeed
    , median(sd_avspeed)     AS median_sd_avspeed
    , sum(median_avspeed)    AS sum_median_avspeed
    , median(median_avspeed) AS median_median_avspeed
  FROM od_1hour
  GROUP BY o,d,weekday,hour
  ORDER BY o,d,weekday,hour
)
;
