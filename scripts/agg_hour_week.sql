SELECT
  o,
  d,
  --time_bucket_gapfill('1 hour', t, '2018-07-09', '2017-10-16') AS hour,
  count(t) as n,
  EXTRACT(dow  FROM t) AS hour,
  EXTRACT(dow  FROM t) AS weekday,
  avg(flow) AS mean_flow,
  STDDEV_SAMP(flow) AS std_flow
FROM od_05min
GROUP BY o,d,weekday,hour
ORDER BY o,d,weekday,hour
LIMIT 10
