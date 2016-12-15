# populate datastudio_dashboards.library_new_return_sessions
# Number of Sessions  - New vs Return
SELECT
  date,
  yoy_include,
  sessions_ma,
  new_sessions_ma,
  return_sessions_ma,
  100*(sessions_ma/ ly_sessions_ma-1) as yoy_sessions_ma,
  100*(new_sessions_ma/ ly_new_sessions_ma-1) as yoy_new_sessions_ma,
  100*(return_sessions_ma/ ly_return_sessions_ma-1) as yoy_return_sessions_ma,
FROM (
  SELECT
    date,
    # new learner exhibit strange trends prior to May 17
    CASE WHEN date>=STRFTIME_UTC_USEC(TIMESTAMP('2016-05-17'), "%Y%m%d") THEN 'include' ELSE 'exclude' END as yoy_include,
    sessions,
    ly_sessions,
    AVG(sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sessions_ma,
    AVG(ly_sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ly_sessions_ma,
    AVG(return_sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_sessions_ma ,
    AVG(ly_return_sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ly_return_sessions_ma ,
    AVG(new_sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS new_sessions_ma ,
    AVG(ly_new_sessions) OVER(ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ly_new_sessions_ma ,
  FROM (
    SELECT
      date,
      sessions,
      LAG(sessions, 364) OVER(ORDER BY date ASC) AS ly_sessions,
      return_sessions,
      LAG(return_sessions, 364) OVER(ORDER BY date ASC) AS ly_return_sessions,
      new_sessions,
      LAG(new_sessions, 364) OVER(ORDER BY date ASC) AS ly_new_sessions,
    FROM (
      SELECT
        date,
        SUM(1) AS sessions,
        SUM(CASE WHEN ud.joined <= DATE_ADD( TIMESTAMP(date_format),-1,"DAY") THEN 1
            ELSE NULL END) as return_sessions,
        SUM(CASE WHEN  ud.joined IS NULL THEN 1
            WHEN ud.joined >=  TIMESTAMP(date) THEN 1
            ELSE NULL END) as new_sessions,
      FROM (
        SELECT
          best_available_id as ka_id,
          STRFTIME_UTC_USEC(start, "%Y%m%d") AS date,
          DATE(start) as date_format,
          SUM(seconds)/60 AS minutes
        FROM
          TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
        WHERE product = 'library'
          AND (domain != 'computing' OR domain IS NULL)
          AND kaid IS NOT NULL
          AND start >= TIMESTAMP('2015-05-07')
        GROUP BY
          ka_id,
          date,
          date_format
        HAVING SUM(seconds)>=30 )  as lt
      # user join date from userdata to determine new v returning user
      LEFT JOIN latest.UserData ud ON lt.ka_id = ud.kaid
    GROUP BY
      date
    ORDER BY
      date )
    )
)
WHERE date>=STRFTIME_UTC_USEC(TIMESTAMP('2015-05-14'), "%Y%m%d")

