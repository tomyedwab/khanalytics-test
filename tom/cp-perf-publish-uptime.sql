# >> tomyedwab.content_tools_metrics_publish_uptime
SELECT
  pubs.day AS day,

  # Number of publish attempts and whether they are successful (English)
  SUM(IF(pubs.locale = 'en', pubs.total, 0)) AS en_publish_attempts,
  SUM(IF(pubs.locale = 'en', pubs.failures, 0)) AS en_publish_failures,
  SUM(IF(pubs.locale = 'intl', pubs.total, 0)) AS intl_publish_attempts,
  SUM(IF(pubs.locale = 'intl', pubs.failures, 0)) AS intl_publish_failures,

FROM

# Publish statistics from weekly backups
(SELECT
    day,
    IF(target_language = 'en' OR target_language IS NULL, 'en', 'intl') AS locale,
    SUM(IF(success = FALSE, 1, 0)) AS failures,
    COUNT(*) AS total

  FROM (
    SELECT
      STRFTIME_UTC_USEC(UTC_USEC_TO_DAY(tps.start_time), "%Y-%m-%d") AS day,
      tps.success AS success,
      pd.target_language AS target_language
    FROM
      [{last_backup}.TopicPublishStatus] tps

  LEFT JOIN EACH [{last_backup}.PublishDiff] pd
  ON pd.__key__.id = tps.publish_diff.id)

  GROUP BY day, locale) pubs

GROUP BY day
