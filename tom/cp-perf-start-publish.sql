# >> tomyedwab.content_tools_metrics_start_publish_incr
SELECT
  CURRENT_TIMESTAMP() AS query_time,
  newpub.week AS week,

  # Quartiles of time to start a publish, in seconds (CMS-based publish)
  newpub.p5_time AS new_publish_start_secs_p5,
  newpub.q1_time AS new_publish_start_secs_q1,
  newpub.median_time AS new_publish_start_secs_median,
  newpub.q3_time AS new_publish_start_secs_q3,
  newpub.p95_time AS new_publish_start_secs_p95,

  # Status of attempts to start a publish (CMS-based publish)
  nps.attempts AS new_publish_start_attempts,
  nps.server_errors AS new_publish_start_server_errors,

  # Quartiles of time to start a publish, in seconds (CMS-based publish)
  old_start.p5_time AS old_publish_start_secs_p5,
  old_start.q1_time AS old_publish_start_secs_q1,
  old_start.median_time AS old_publish_start_secs_median,
  old_start.q3_time AS old_publish_start_secs_q3,
  old_start.p95_time AS old_publish_start_secs_p95,

  # Status of attempts to start a publish (CMS-based publish)
  old_start_status.attempts AS old_publish_start_attempts,
  old_start_status.server_errors AS old_publish_start_server_errors,

  # Quartiles of time to load the revision SHAs, when loading Publish in the CMS
  cmspub.p5_time AS cmspub_secs_p5,
  cmspub.q1_time AS cmspub_secs_q1,
  cmspub.median_time AS cmspub_secs_median,
  cmspub.q3_time AS cmspub_secs_q3,
  cmspub.p95_time AS cmspub_secs_p95,

  # Status of attempts to load Publish in the CMS
  cmspubstatus.attempts AS cmspub_attempts,
  cmspubstatus.server_errors AS cmspub_server_errors,

  # Quartiles of time to load the old publish page
  pn.p5_time AS old_publish_load_secs_p5,
  pn.q1_time AS old_publish_load_secs_q1,
  pn.median_time AS old_publish_load_secs_median,
  pn.q3_time AS old_publish_load_secs_q3,
  pn.p95_time AS old_publish_load_secs_p95,

  # Status of attempts to load the old publish page
  pnstatus.attempts AS old_publish_load_attempts,
  pnstatus.server_errors AS old_publish_load_server_errors

FROM

# Time taken by API endpoints corresponding to starting a publish
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE  resource CONTAINS 'internal/dev/edit/start_publish_from_topic_tree' AND status = 200
    GROUP BY week) newpub

LEFT JOIN EACH

# Status for API endpoints corresponding to starting a publish
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE  resource CONTAINS 'internal/dev/edit/start_publish_from_topic_tree'
    GROUP BY week) nps

ON newpub.week = nps.week

LEFT JOIN EACH

# Time taken by API endpoint for loading CMS-based publish
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS 'edit/revision_shas_and_modifications' AND status = 200
    GROUP BY week) cmspub

ON newpub.week = cmspub.week

LEFT JOIN EACH

# Status for API endpoint for loading CMS-based publish
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS 'edit/revision_shas_and_modifications'
    GROUP BY week) cmspubstatus

ON newpub.week = cmspubstatus.week

LEFT JOIN EACH

# Most of the time spent loading the old "new publish" page is spent in this API call
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS '/dev/edit/publish/new' AND method='GET' AND status = 200
    GROUP BY week) pn

ON newpub.week = pn.week

LEFT JOIN EACH

# Status for old "new publish" page API load endpoint
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS '/dev/edit/publish/new' AND method='GET'
    GROUP BY week) pnstatus

ON newpub.week = pnstatus.week

LEFT JOIN EACH

# API call to start a publish
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    NTH(5, QUANTILES(end_time-start_time,101)) AS p5_time,
    NTH(25, QUANTILES(end_time-start_time,101)) AS q1_time,
    NTH(50, QUANTILES(end_time-start_time,101)) AS median_time,
    NTH(75, QUANTILES(end_time-start_time,101)) AS q3_time,
    NTH(95, QUANTILES(end_time-start_time,101)) AS p95_time
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS '/dev/edit/publish/new' AND method='POST' AND status = 200
    GROUP BY week) old_start

ON newpub.week = old_start.week

LEFT JOIN EACH

# Status for old "new publish" page API start endpoint
(SELECT
    STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(INTEGER(start_time*1000000), 1), "%Y-%m-%d") AS week,
    COUNT(*) AS attempts,
    SUM(status = 500) AS server_errors
    FROM TABLE_DATE_RANGE(logs.requestlogs_, USEC_TO_TIMESTAMP(UTC_USEC_TO_WEEK(NOW(), 1)-1000000*60*60*24*14), CURRENT_TIMESTAMP())
    WHERE resource CONTAINS '/dev/edit/publish/new' AND method='POST'
    GROUP BY week) old_start_status

ON newpub.week = old_start_status.week
