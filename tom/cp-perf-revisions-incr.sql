# >> tomyedwab.content_tools_metrics_revisions_incr
SELECT
  CURRENT_TIMESTAMP() AS query_time,
  edit.week AS week,

  # Quartiles of time to save a new content item to the server, in seconds
  SUM(IF(edit.method = 'POST', edit.p5_time, 0)) AS create_secs_p5,
  SUM(IF(edit.method = 'POST', edit.q1_time, 0)) AS create_secs_q1,
  SUM(IF(edit.method = 'POST', edit.median_time, 0)) AS create_secs_median,
  SUM(IF(edit.method = 'POST', edit.q3_time, 0)) AS create_secs_q3,
  SUM(IF(edit.method = 'POST', edit.p95_time, 0)) AS create_secs_p95,

  # Status of attempts to save a new content item
  SUM(IF(edit.method = 'POST', es.attempts, 0)) AS create_attempts,
  SUM(IF(edit.method = 'POST', es.validation_errors, 0)) AS create_validation_errors,
  SUM(IF(edit.method = 'POST', es.server_errors, 0)) AS create_server_errors,

  # Quartiles of time to edit an existing content item to the server, in seconds
  SUM(IF(edit.method = 'PUT', edit.p5_time, 0)) AS edit_secs_p5,
  SUM(IF(edit.method = 'PUT', edit.q1_time, 0)) AS edit_secs_q1,
  SUM(IF(edit.method = 'PUT', edit.median_time, 0)) AS edit_secs_median,
  SUM(IF(edit.method = 'PUT', edit.q3_time, 0)) AS edit_secs_q3,
  SUM(IF(edit.method = 'PUT', edit.p95_time, 0)) AS edit_secs_p95,

  # Status of attempts to edit an existing content item
  SUM(IF(edit.method = 'PUT', es.attempts, 0)) AS edit_attempts,
  SUM(IF(edit.method = 'PUT', es.validation_errors, 0)) AS edit_validation_errors,
  SUM(IF(edit.method = 'PUT', es.server_errors, 0)) AS edit_server_errors,

  # Quartiles of time to load content from the server, in seconds
  SUM(IF(edit.method = 'GET', edit.p5_time, 0)) AS load_secs_p5,
  SUM(IF(edit.method = 'GET', edit.q1_time, 0)) AS load_secs_q1,
  SUM(IF(edit.method = 'GET', edit.median_time, 0)) AS load_secs_median,
  SUM(IF(edit.method = 'GET', edit.q3_time, 0)) AS load_secs_q3,
  SUM(IF(edit.method = 'GET', edit.p95_time, 0)) AS load_secs_p95,

  # Status of attempts to load content
  SUM(IF(edit.method = 'GET', es.attempts, 0)) AS load_attempts,
  SUM(IF(edit.method = 'GET', es.validation_errors, 0)) AS load_validation_errors,
  SUM(IF(edit.method = 'GET', es.server_errors, 0)) AS load_server_errors
FROM

# Time taken by API endpoints corresponding to editing content
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    method,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE REGEXP_MATCH(resource, 'internal/dev/edit/(topic|article|exercise|video)')
      AND (method = 'POST' OR method = 'PUT' OR method = 'GET')
      AND status = 200
    GROUP BY week, method) edit

LEFT JOIN EACH

# Status for API endpoints corresponding to editing content
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    method,
    COUNT(*) AS attempts,
    SUM(status = 400) AS validation_errors,
    SUM(status = 500) AS server_errors
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE REGEXP_MATCH(resource, 'internal/dev/edit/(topic|article|exercise|video)')
      AND (method = 'POST' OR method = 'PUT' OR method = 'GET')
    GROUP BY week, method) es

ON edit.week = es.week AND edit.method = es.method

GROUP BY week
