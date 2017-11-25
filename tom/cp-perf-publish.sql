# >> tomyedwab.content_tools_metrics_publish
SELECT
  pubs.week AS week,

  # Number of publish attempts and whether they are successful (English)
  SUM(IF(pubs.locale = 'en', pubs.total, 0)) AS en_publish_attempts,
  SUM(IF(pubs.locale = 'en', pubs.failures, 0)) AS en_publish_failures,
  SUM(IF(pubs.locale = 'en', pubs.retries, 0)) AS en_publish_retries,

  # Publish processing time, in minutes (English)
  SUM(IF(pubs.locale = 'en', pubs.p5_time, 0)) AS en_publish_minutes_p5,
  SUM(IF(pubs.locale = 'en', pubs.q1_time, 0)) AS en_publish_minutes_q1,
  SUM(IF(pubs.locale = 'en', pubs.median_time, 0)) AS en_publish_minutes_median,
  SUM(IF(pubs.locale = 'en', pubs.q3_time, 0)) AS en_publish_minutes_q3,
  SUM(IF(pubs.locale = 'en', pubs.p95_time, 0)) AS en_publish_minutes_p95,

  # Publish total time, in minutes (English)
  SUM(IF(pubs.locale = 'en', pubs.p5_total_time, 0)) AS en_publish_total_p5,
  SUM(IF(pubs.locale = 'en', pubs.q1_total_time, 0)) AS en_publish_total_q1,
  SUM(IF(pubs.locale = 'en', pubs.median_total_time, 0)) AS en_publish_total_median,
  SUM(IF(pubs.locale = 'en', pubs.q3_total_time, 0)) AS en_publish_total_q3,
  SUM(IF(pubs.locale = 'en', pubs.p95_total_time, 0)) AS en_publish_total_p95,

  # Number of publish attempts and whether they are successful (International)
  SUM(IF(pubs.locale = 'intl', pubs.total, 0)) AS intl_publish_attempts,
  SUM(IF(pubs.locale = 'intl', pubs.failures, 0)) AS intl_publish_failures,
  SUM(IF(pubs.locale = 'intl', pubs.retries, 0)) AS intl_publish_retries,

  # Publish processing time, in minutes (International)
  SUM(IF(pubs.locale = 'intl', pubs.p5_time, 0)) AS intl_publish_minutes_p5,
  SUM(IF(pubs.locale = 'intl', pubs.q1_time, 0)) AS intl_publish_minutes_q1,
  SUM(IF(pubs.locale = 'intl', pubs.median_time, 0)) AS intl_publish_minutes_median,
  SUM(IF(pubs.locale = 'intl', pubs.q3_time, 0)) AS intl_publish_minutes_q3,
  SUM(IF(pubs.locale = 'intl', pubs.p95_time, 0)) AS intl_publish_minutes_p95,

  # Publish total time, in minutes (International)
  SUM(IF(pubs.locale = 'intl', pubs.p5_total_time, 0)) AS intl_publish_total_p5,
  SUM(IF(pubs.locale = 'intl', pubs.q1_total_time, 0)) AS intl_publish_total_q1,
  SUM(IF(pubs.locale = 'intl', pubs.median_total_time, 0)) AS intl_publish_total_median,
  SUM(IF(pubs.locale = 'intl', pubs.q3_total_time, 0)) AS intl_publish_total_q3,
  SUM(IF(pubs.locale = 'intl', pubs.p95_total_time, 0)) AS intl_publish_total_p95,

FROM

# Publish statistics from weekly backups
(SELECT
    week,
    IF(target_language = 'en' OR target_language IS NULL, 'en', 'intl') AS locale,

    NTH(5, QUANTILES(time, 101)) AS p5_time,
    NTH(25, QUANTILES(time, 101)) AS q1_time,
    NTH(50, QUANTILES(time, 101)) AS median_time,
    NTH(75, QUANTILES(time, 101)) AS q3_time,
    NTH(95, QUANTILES(time, 101)) AS p95_time,

    NTH(5, QUANTILES(total_time, 101)) AS p5_total_time,
    NTH(25, QUANTILES(total_time, 101)) AS q1_total_time,
    NTH(50, QUANTILES(total_time, 101)) AS median_total_time,
    NTH(75, QUANTILES(total_time, 101)) AS q3_total_time,
    NTH(95, QUANTILES(total_time, 101)) AS p95_total_time,

    SUM(IF(success = FALSE, 1, 0)) AS failures,
    SUM(IF(retry_count > 0 AND success = TRUE, 1, 0)) AS retries,
    COUNT(*) AS total

  FROM (
    SELECT
      STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(tps.start_time, 1), "%Y-%m-%d") AS week,
      FLOAT(JSON_EXTRACT(tps.profile, '$[1].time'))/60.0 AS time,
      (tps.end_time - tps.queue_insert_time) / 60000000.0 AS total_time,
      tps.success AS success,
      tps.retry_count AS retry_count,
      pd.target_language AS target_language
    FROM
      [{last_backup}.TopicPublishStatus] tps

  LEFT JOIN EACH [{last_backup}.PublishDiff] pd
  ON pd.__key__.id = tps.publish_diff.id)

  GROUP BY week, locale) pubs

GROUP BY week
