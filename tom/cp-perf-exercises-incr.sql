# >> tomyedwab.content_tools_metrics_exercises_incr
SELECT
  CURRENT_TIMESTAMP() AS query_time,
  edit.week AS week,

  # Quartiles of time to load editing exercise data, in seconds
  edit.p5_time AS load_secs_p5,
  edit.q1_time AS load_secs_q1,
  edit.median_time AS load_secs_median,
  edit.q3_time AS load_secs_q3,
  edit.p95_time AS load_secs_p95,

  # Status of attempts to load editing exercise data
  es.attempts AS load_attempts,
  es.server_errors AS load_server_errors,

  # Quartiles of time to save exercise items, in seconds
  item.p5_time AS item_save_secs_p5,
  item.q1_time AS item_save_secs_q1,
  item.median_time AS item_save_secs_median,
  item.q3_time AS item_save_secs_q3,
  item.p95_time AS item_save_secs_p95,

  # Status of attempts to save exercise items
  is.attempts AS item_save_attempts,
  is.server_errors AS item_save_server_errors
FROM

# Time taken by API endpoint for loading an exercise for editing
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE REGEXP_MATCH(resource, '/api/internal/exercises/[x1-9a-f]+/edit') AND method = 'GET' AND status = 200
    GROUP BY week) edit

LEFT JOIN EACH

# Status for API endpoint for loading an exercise for editing
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors,
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE REGEXP_MATCH(resource, '/api/internal/exercises/[x1-9a-f]+/edit') AND method = 'GET'
    GROUP BY week) es

ON edit.week = es.week

LEFT JOIN EACH

(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS '/api/internal/assessment_items/' AND method = "PUT" AND NOT (resource CONTAINS 'set_live') AND status = 200
    GROUP BY week) item

ON edit.week = item.week

LEFT JOIN EACH

# Status for API endpoint for loading an exercise for editing
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors,
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS '/api/internal/assessment_items/' AND method = "PUT" AND NOT (resource CONTAINS 'set_live')
    GROUP BY week) is

ON edit.week = is.week
