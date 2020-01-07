INSERT INTO
  agg_15min_weekdaycat (
    o,d,period,weekdaycat,sum_flow,median_flow,
    sum_mean_avspeed,median_mean_avspeed,
    sum_sd_avspeed, median_sd_avspeed,
    sum_median_avspeed, median_median_avspeed)
(
  SELECT
      o
    , d
    , t::time                                       AS period
    , dowcat(CAST(EXTRACT(dow FROM t) AS INTEGER))  AS weekdaycat
    , sum(flow)                                     AS sum_flow
    , median(flow)                                  AS median_flow
    , sum(mean_avspeed)                             AS sum_mean_avspeed
    , median(mean_avspeed)                          AS median_mean_avspeed
    , sum(sd_avspeed)                               AS sum_sd_avspeed
    , median(sd_avspeed)                            AS median_sd_avspeed
    , sum(median_avspeed)                           AS sum_median_avspeed
    , median(median_avspeed)                        AS median_median_avspeed
  FROM od_15min
  GROUP BY o,d,weekdaycat,period
  ORDER BY o,d,weekdaycat,period
)
ON CONFLICT DO NOTHING
;
