#  populate datastudio_dashboards.library_daily_learning_time
# generate data for daily TLT and yoy growth - 7 and 28 days moving average

SELECT
  date,
  CASE WHEN date>=STRFTIME_UTC_USEC(TIMESTAMP('2016-05-14'), "%Y%m%d")  THEN 'include' ELSE 'exclude' END as week_yoy_include,
  CASE WHEN date>=STRFTIME_UTC_USEC(TIMESTAMP('2016-06-04'), "%Y%m%d")  THEN 'include' ELSE 'exclude' END as month_yoy_include,
  CASE WHEN date>=STRFTIME_UTC_USEC(TIMESTAMP('2015-05-14'), "%Y%m%d")  THEN 'include' ELSE 'exclude' END as week_include,
  CASE WHEN date>=STRFTIME_UTC_USEC(TIMESTAMP('2015-06-04'), "%Y%m%d")  THEN 'include' ELSE 'exclude' END as month_include,
  this_year_mins AS daily_learning_time,
  this_year_mins_weekma AS daily_learning_time_weekma,
  this_year_mins_monthma as daily_learning_time_monthma,
  100*(this_year_mins/last_year_mins-1) AS yoy_growth,
  100*(this_year_mins_weekma/last_year_mins_weekma-1) AS yoy_growth_weekma,
  100*(this_year_mins_monthma/last_year_mins_monthma-1) AS yoy_growth_monthma,
FROM (
  SELECT
    date,
    AVG(minutes) as this_year_mins,
    LAG(minutes, 364) OVER (ORDER BY date) AS last_year_mins,
    AVG(minutes) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS this_year_mins_weekma,
    AVG(minutes) OVER (ORDER BY date ROWS BETWEEN 364+6 PRECEDING AND 364 PRECEDING) AS last_year_mins_weekma,
    AVG(minutes) OVER (ORDER BY date ROWS BETWEEN 27 PRECEDING AND CURRENT ROW) AS this_year_mins_monthma,
    AVG(minutes) OVER (ORDER BY date ROWS BETWEEN 364+27 PRECEDING AND 364 PRECEDING) AS last_year_mins_monthma,
  FROM (
    /* table of TLT by day */
    SELECT
      STRFTIME_UTC_USEC(start, "%Y%m%d") AS date,
      SUM(seconds) / 60 AS minutes
    FROM
      TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
      WHERE product = 'library'
      AND (domain!= 'computing'
          OR domain IS NULL)
    GROUP BY
      date
  )
  GROUP BY
    date,  minutes
)
ORDER BY date

