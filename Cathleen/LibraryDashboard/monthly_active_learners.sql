# populate datastudio_dashboards.library_monthly_learners
# Monthly active learners and avg number of sessions per learner
# All months adjusted for 28 days in a month
SELECT
  month,
  CASE WHEN month=STRFTIME_UTC_USEC( USEC_TO_TIMESTAMP(NOW()), "%Y%m")
        AND DAY(USEC_TO_TIMESTAMP(NOW())) <=28
      THEN 'exclude'
     ELSE 'include' END as current_exclude,
  CASE WHEN month<=STRFTIME_UTC_USEC( TIMESTAMP('2016-05-01'), "%Y%m") THEN 'exclude'
    WHEN month=STRFTIME_UTC_USEC( USEC_TO_TIMESTAMP(NOW()), "%Y%m")
      THEN 'exclude'
     ELSE 'include' END as yoy_include,
  active_learners,
  (active_learners/ly_active_learners-1)*100 as yoy_active_learners,
  avg_sessions,
  (avg_sessions/ly_avg_sessions-1)*100 as yoy_avg_sessions,
FROM (
  SELECT
    month,
    active_learners,
    avg_sessions,
    LAG(active_learners, 12) OVER(ORDER BY month ASC) AS ly_active_learners,
    LAG(avg_sessions, 12) OVER(ORDER BY month ASC) AS ly_avg_sessions,
  FROM (
    SELECT
      month,
      SUM(1) as active_learners,
      AVG(sessions) as avg_sessions
    FROM (
      SELECT
        # formmatted month date
        month,
        kaid,
        SUM(1) as sessions
      FROM (
        SELECT
          kaid,
          STRFTIME_UTC_USEC( start, "%Y%m") as month,
          DAY(start) as day,
          SUM(seconds) as seconds,
        FROM
          TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
        WHERE
          kaid IS NOT NULL
          # include only non-cs library content
          AND product='library'
          AND  (domain!='computing' OR domain IS NULL)
          # only include activity on content pages
          AND activity IN ('video','exercise','article')
        GROUP BY
          kaid,
          month,
          day
        )
      #  adjust all months to 28 days
      WHERE day<=28
      GROUP BY month, kaid
      HAVING SUM(seconds)>=30
      )
    GROUP BY month
    ORDER BY month
    )
)
WHERE month > STRFTIME_UTC_USEC( TIMESTAMP('2015-05-01'), "%Y%m")






