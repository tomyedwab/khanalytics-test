# >> tomyedwab.content_tools_metrics_load_incr
SELECT
  CURRENT_TIMESTAMP() AS query_time,
  article.week AS week,

  # Quartiles of time to load the article editor, in seconds
  article.p5_time AS article_secs_p5,
  article.q1_time AS article_secs_q1,
  article.median_time AS article_secs_median,
  article.q3_time AS article_secs_q3,
  article.p95_time AS article_secs_p95,

  # Status of attempts to load the article editor
  articlestatus.attempts AS article_loads,
  articlestatus.server_errors AS article_server_errors,

  # Quartiles of time to load the exercise editor, in seconds
  exercise.p5_time AS exercise_secs_p5,
  exercise.q1_time AS exercise_secs_q1,
  exercise.median_time AS exercise_secs_median,
  exercise.q3_time AS exercise_secs_q3,
  exercise.p95_time AS exercise_secs_p95,

  # Status of attempts to load the exercise editor
  exercisestatus.attempts AS exercise_loads,
  exercisestatus.server_errors AS exercise_server_errors,
FROM

# Time taken by article page handler
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE elog_url_route CONTAINS '/devadmin/content/articles' AND status = 200
    GROUP BY week) article

LEFT JOIN EACH

# Status for article page handler
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE elog_url_route CONTAINS '/devadmin/content/articles'
    GROUP BY week) articlestatus

ON article.week = articlestatus.week

LEFT JOIN EACH

# Time taken by exercise page handler
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE elog_url_route CONTAINS '/devadmin/content/exercises' AND status = 200
    GROUP BY week) exercise

ON article.week = exercise.week

LEFT JOIN EACH

# Status for exercise page handler
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE elog_url_route CONTAINS '/devadmin/content/exercises'
    GROUP BY week) exercisestatus

ON article.week = exercisestatus.week
