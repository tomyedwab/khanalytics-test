# populate datastudio_dashboards.library_retention_trends
# How many individuals are retained 1 week / 2 weeks / month after session on date
# Include all sessions with at least 30 seconds, and breakdown by new vs returning learners
SELECT
  date,
  CASE WHEN date >= STRFTIME_UTC_USEC( TIMESTAMP('2016-08-01'),"%Y%m%d")  THEN 'include' ELSE 'exclude' END as yoy_include,
  CASE WHEN  DATEDIFF( DATE(USEC_TO_TIMESTAMP(NOW())),  date )>=28 THEN 'include' ELSE 'exclude' END as recent_exclude,
  # all learners
  return_within_1_week,
  return_within_2_weeks,
  return_within_1_month,
  100*( return_within_1_week/ly_return_within_1_week -1) as yoy_return_within_1_week,
  100*( return_within_2_weeks/ly_return_within_2_weeks -1) as yoy_return_within_2_weeks,
  100*( return_within_1_month/ly_return_within_1_month -1) as yoy_return_within_1_month,
  # new learners
  return_within_1_week_new,
  return_within_2_weeks_new,
  return_within_1_month_new,
  100*( return_within_1_week_new/ly_return_within_1_week_new -1) as yoy_return_within_1_week_new,
  100*( return_within_2_weeks_new/ly_return_within_2_weeks_new -1) as yoy_return_within_2_weeks_new,
  100*( return_within_1_month_new/ly_return_within_1_month_new -1) as yoy_return_within_1_month_new,
  # return learners
  return_within_1_week_old,
  return_within_2_weeks_old,
  return_within_1_month_old,
  100*( return_within_1_week_old/ly_return_within_1_week_old -1) as yoy_return_within_1_week_old,
  100*( return_within_2_weeks_old/ly_return_within_2_weeks_old -1) as yoy_return_within_2_weeks_old,
  100*( return_within_1_month_old/ly_return_within_1_month_old -1) as yoy_return_within_1_month_old,
FROM (
  SELECT
     date,
     # all learners this year
     return_within_1_week_ma as return_within_1_week,
     return_within_2_weeks_ma as return_within_2_weeks,
     return_within_1_month_ma as return_within_1_month,
     # all learners last year to date, matched on weekday
     LAG(return_within_1_week_ma, 364) OVER(ORDER BY date ASC) as ly_return_within_1_week,
     LAG(return_within_2_weeks_ma, 364) OVER(ORDER BY date ASC) as ly_return_within_2_weeks,
     LAG(return_within_1_month_ma, 364) OVER(ORDER BY date ASC) as ly_return_within_1_month,

     # new learners this year
     return_within_1_week_new_ma as return_within_1_week_new,
     return_within_2_weeks_new_ma as return_within_2_weeks_new,
     return_within_1_month_new_ma as return_within_1_month_new,
     # all learners last year to date, matched on weekday
     LAG(return_within_1_week_new_ma, 364) OVER( ORDER BY date ASC) as ly_return_within_1_week_new,
     LAG(return_within_2_weeks_new_ma, 364) OVER( ORDER BY date ASC) as ly_return_within_2_weeks_new,
     LAG(return_within_1_month_new_ma, 364) OVER( ORDER BY date ASC) as ly_return_within_1_month_new,

     # return learners this year
     return_within_1_week_old_ma as return_within_1_week_old,
     return_within_2_weeks_old_ma as return_within_2_weeks_old,
     return_within_1_month_old_ma as return_within_1_month_old,
     # return learners last year to date, matched on weekday
     LAG(return_within_1_week_old_ma, 364) OVER( ORDER BY date ASC) as ly_return_within_1_week_old,
     LAG(return_within_2_weeks_old_ma, 364) OVER( ORDER BY date ASC) as ly_return_within_2_weeks_old,
     LAG(return_within_1_month_old_ma, 364) OVER( ORDER BY date ASC) as ly_return_within_1_month_old,

  FROM (
    SELECT
      date,
      # 1 week moving average all learner
      AVG(100*return_within_1_week) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_1_week_ma,
      AVG(100*return_within_2_weeks) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_2_weeks_ma,
      AVG(100*return_within_1_month) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_1_month_ma,
      # 1 week moving average new learner
      AVG(100*return_within_1_week_new) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_1_week_new_ma,
      AVG(100*return_within_2_weeks_new) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_2_weeks_new_ma,
      AVG(100*return_within_1_month_new) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_1_month_new_ma,

      # 1 week moving average return learner
      AVG(100*return_within_1_week_old) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_1_week_old_ma,
      AVG(100*return_within_2_weeks_old) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_2_weeks_old_ma,
      AVG(100*return_within_1_month_old) OVER( ORDER BY date_format ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS return_within_1_month_old_ma,

    FROM (
      SELECT
        date,
        date_format,
        SUM(1) as learners,
        SUM(CASE WHEN next_date IS NOT NULL
          AND next_date<=date_7_days THEN 1  ELSE 0 END)/SUM(1) as return_within_1_week,
        SUM(CASE WHEN next_date IS NOT NULL
          AND next_date<=date_14_days THEN 1  ELSE 0 END)/SUM(1) as return_within_2_weeks,
        SUM(CASE WHEN next_date IS NOT NULL
          AND next_date<=date_28_days THEN 1  ELSE 0 END)/SUM(1) as return_within_1_month,
        # new learners
        SUM(1-return_learner) as new_learners,
        SUM(CASE WHEN  next_date IS NOT NULL
          AND next_date<=date_7_days THEN 1-return_learner  ELSE 0 END)/SUM(1-return_learner) as return_within_1_week_new,
        SUM(CASE WHEN next_date IS NOT NULL
          AND next_date<=date_14_days THEN 1-return_learner  ELSE 0 END)/SUM(1-return_learner) as return_within_2_weeks_new,
        SUM(CASE WHEN next_date IS NOT NULL
          AND next_date<=date_28_days THEN 1-return_learner ELSE 0 END)/SUM(1-return_learner) as return_within_1_month_new,
        # return learners
        SUM(return_learner) as return_learners,
        SUM(CASE WHEN  next_date IS NOT NULL
          AND next_date<=date_7_days THEN return_learner  ELSE 0 END)/SUM(return_learner) as return_within_1_week_old,
        SUM(CASE WHEN next_date IS NOT NULL
          AND next_date<=date_14_days THEN return_learner  ELSE 0 END)/SUM(return_learner) as return_within_2_weeks_old,
        SUM(CASE WHEN next_date IS NOT NULL
          AND next_date<=date_28_days THEN return_learner ELSE 0 END)/SUM(return_learner) as return_within_1_month_old,

      FROM (
          SELECT
            lt.kaid as kaid,
            (CASE WHEN ud.joined < TIMESTAMP(lt.date) THEN 1
              WHEN ud.joined >=  TIMESTAMP(lt.date) THEN 0
              WHEN ud.joined IS NULL THEN 0
              ELSE NULL END) as return_learner,
            date,
            date_format,
            date_7_days,
            date_14_days,
            date_28_days,
            LEAD(date_format) over (PARTITION BY lt.kaid ORDER BY date_format) as next_date,
          FROM (
            SELECT
              kaid,
              STRFTIME_UTC_USEC(start, "%Y%m%d")  as date,
              DATE(start) as date_format,
              DATE( DATE_ADD(start,7,"DAY")) as date_7_days,
              DATE( DATE_ADD(start,14,"DAY")) as date_14_days,
              DATE( DATE_ADD(start,28,"DAY")) as date_28_days,
            FROM TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
            # include only non-cs library content
            WHERE product = 'library'
              AND device = 'desktop'
              AND  (domain!= 'computing'
                  OR domain IS NULL)
              AND kaid IS NOT NULL
            GROUP BY kaid, date, date_format, date_7_days, date_14_days, date_28_days
            HAVING SUM(seconds)>=30
          ) as lt
        LEFT JOIN latest.UserData ud
          ON lt.kaid = ud.kaid
      )
      GROUP BY date, date_format
      ORDER BY  date
   )
  )
)
