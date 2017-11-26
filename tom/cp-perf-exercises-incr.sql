# >> tomyedwab.content_tools_metrics_exercises_incr
SELECT
  CURRENT_TIMESTAMP() AS query_time,
  edit.week AS week,

  # Quartiles of time to load editing exercise data, in seconds
  edit.times[OFFSET(1)] AS load_secs_p5,
  edit.times[OFFSET(6)] AS load_secs_q1,
  edit.times[OFFSET(10)] AS load_secs_median,
  edit.times[OFFSET(16)] AS load_secs_q3,
  edit.times[OFFSET(20)] AS load_secs_p95,

  # Status of attempts to load editing exercise data
  editstatus.attempts AS load_attempts,
  editstatus.server_errors AS load_server_errors,

  # Quartiles of time to save exercise items, in seconds
  item.times[OFFSET(1)] AS item_save_secs_p5,
  item.times[OFFSET(6)] AS item_save_secs_q1,
  item.times[OFFSET(10)] AS item_save_secs_median,
  item.times[OFFSET(16)] AS item_save_secs_q3,
  item.times[OFFSET(20)] AS item_save_secs_p95,

  # Status of attempts to save exercise items
  itemstatus.attempts AS item_save_attempts,
  itemstatus.server_errors AS item_save_server_errors
FROM

# Time taken by API endpoint for loading an exercise for editing
(SELECT
    FORMAT_DATE("%Y-%m-%d", DATE_TRUNC(DATE_FROM_UNIX_DATE(CAST(start_time/(60*60*24) AS INT64)), WEEK)) AS week,
    APPROX_QUANTILES(end_time - start_time, 20) AS times
    FROM `logs.requestlogs_*`
    WHERE
        REGEXP_CONTAINS(resource, r'^/api/internal/exercises/[x0-9a-f]+/edit$')
        AND method = 'GET'
        AND status = 200
        AND _TABLE_SUFFIX BETWEEN 
            FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY))
            AND FORMAT_DATE("%Y%m%d", DATE(TIMESTAMP "2017-10-01 00:00:00"))
    GROUP BY week) edit

LEFT JOIN

# Status for API endpoint for loading an exercise for editing
(SELECT
    FORMAT_DATE("%Y-%m-%d", DATE_TRUNC(DATE_FROM_UNIX_DATE(CAST(start_time/(60*60*24) AS INT64)), WEEK)) AS week,
    COUNT(*) AS attempts,
    COUNTIF(status = 500) AS server_errors
    FROM `logs.requestlogs_*`
    WHERE
        REGEXP_CONTAINS(resource, r'^/api/internal/exercises/[x0-9a-f]+/edit$')
        AND method = 'GET'
        AND _TABLE_SUFFIX BETWEEN 
            FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY))
            AND FORMAT_DATE("%Y%m%d", CURRENT_DATE())
    GROUP BY week) editstatus

ON edit.week = editstatus.week

LEFT JOIN

(SELECT
    FORMAT_DATE("%Y-%m-%d", DATE_TRUNC(DATE_FROM_UNIX_DATE(CAST(start_time/(60*60*24) AS INT64)), WEEK)) AS week,
    APPROX_QUANTILES(end_time - start_time, 20) AS times
    FROM `logs.requestlogs_*`
    WHERE
        resource LIKE '%/api/internal/assessment_items/%'
        AND method = "PUT"
        AND NOT (resource LIKE '%set_live%')
        AND status = 200
        AND _TABLE_SUFFIX BETWEEN 
            FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY))
            AND FORMAT_DATE("%Y%m%d", CURRENT_DATE())
    GROUP BY week) item

ON edit.week = item.week

LEFT JOIN

# Status for API endpoint for loading an exercise for editing
(SELECT
    FORMAT_DATE("%Y-%m-%d", DATE_TRUNC(DATE_FROM_UNIX_DATE(CAST(start_time/(60*60*24) AS INT64)), WEEK)) AS week,
    COUNT(*) AS attempts,
    COUNTIF(status = 500) AS server_errors
    FROM `logs.requestlogs_*`
    WHERE
        resource LIKE '%/api/internal/assessment_items/%'
        AND method = "PUT"
        AND NOT (resource LIKE '%set_live%')
        AND _TABLE_SUFFIX BETWEEN 
            FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY))
            AND FORMAT_DATE("%Y%m%d", CURRENT_DATE())
    GROUP BY week) itemstatus

ON edit.week = itemstatus.week
