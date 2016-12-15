# populate datastudio_dashboards.library_daily_sessions
# Session count and average session length
SELECT
  date,
  CASE WHEN date>=STRFTIME_UTC_USEC(TIMESTAMP('2016-05-14'), "%Y%m%d")  THEN 'include' ELSE 'exclude' END as yoy_include,
  session_length,
  100*(session_length/ly_session_length-1) AS session_length_yoy_growth,
  sessions,
  100*(sessions/ly_sessions-1) AS sessions_yoy_growth,
  session_length_ma,
  100*(session_length_ma/ly_session_length_ma-1) AS session_length_ma_yoy_growth,
  sessions_ma,
  100*(sessions_ma/ly_sessions_ma-1) AS sessions_ma_yoy_growth,
FROM (
  SELECT
    date,
    session_length,
    ly_session_length,
    sessions,
    ly_sessions,
    AVG(session_length) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS session_length_ma,
    AVG(ly_session_length) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ly_session_length_ma,
    AVG(sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sessions_ma,
    AVG(ly_sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ly_sessions_ma,
  FROM (
    SELECT
      date,
      session_length,
      LAG(session_length, 364) OVER(ORDER BY date ASC) AS ly_session_length,
      sessions,
      LAG(sessions, 364) OVER(ORDER BY date ASC) AS ly_sessions,
    FROM (
      # daily average session length and total sessions
      SELECT
        date,
        AVG(CASE WHEN seconds>=30 THEN seconds/60 ELSE NULL END) AS session_length,
        SUM(CASE WHEN seconds>=30 THEN 1 ELSE NULL END) AS sessions,
      FROM (
        # session length by date and learner
        SELECT
          kaid,
          STRFTIME_UTC_USEC(start, "%Y%m%d") AS date,
          SUM(seconds) AS seconds
        FROM
          TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
        WHERE
          # exclude sessions that did not meet threshold for kaid creation
          kaid IS NOT NULL
          # include only non-cs library content
          AND product='library'
          AND (domain!='computing' OR domain IS NULL)
        GROUP BY
          kaid,
          date
        )
     GROUP BY
      date
    ORDER BY
      date )
  )
)
# filter out dates without enough days for a 7 day moving avg
WHERE date >= STRFTIME_UTC_USEC(TIMESTAMP('2015-05-14'), "%Y%m%d")
