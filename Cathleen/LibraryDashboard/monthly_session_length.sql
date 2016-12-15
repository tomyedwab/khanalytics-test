# populate datastudio_dashboards.library_monthly_session_length
# Monthly session length data, only include sessions with at least 30 seconds
SELECT
  date,
  CASE WHEN date=STRFTIME_UTC_USEC( USEC_TO_TIMESTAMP(NOW()), "%Y%m")
        AND DAY(USEC_TO_TIMESTAMP(NOW())) <=28
      THEN 'exclude'
     ELSE 'include' END as current_exclude,
  CASE WHEN date> STRFTIME_UTC_USEC( TIMESTAMP('2016-05-14'), "%Y%m")
    THEN 'include' ELSE 'exclude' END as yoy_include,
  avg_session_length ,
  (avg_session_length/ly_avg_session_length-1)*100 as yoy_growth,
FROM (
  SELECT
    date,
    avg_session_length,
    LAG(avg_session_length, 12) OVER(ORDER BY date ASC) AS ly_avg_session_length,
  FROM (
    # daily average session length and total sessions
    SELECT
      # formatted date for data studio
      date,
      AVG(minutes) AS avg_session_length,
    FROM (
      # session length by date and learner
      SELECT
        kaid,
        STRFTIME_UTC_USEC(start, "%Y%m") AS date,
        DATE(start) AS date_ts,
        SUM(seconds)/60 AS minutes
      FROM
        TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
      WHERE
        kaid IS NOT NULL
        # include only non-cs library content
        AND product='library'
        AND (domain!='computing' OR domain IS NULL)
        AND activity IN ('video','exercise','article')
      GROUP BY
        kaid,
        date,
        date_ts
      HAVING SUM(seconds)>=30 )
   GROUP BY
    date
))
# filter out months without full month of data
WHERE date>= STRFTIME_UTC_USEC( TIMESTAMP('2015-05-01'), "%Y%m")


