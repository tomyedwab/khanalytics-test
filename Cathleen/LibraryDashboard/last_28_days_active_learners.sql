# populate datastudio_dashboards.library_last_28_days_learners
# Last 28 Days Active User
SELECT
   MAX(active_learners) as active_learners,
   (MAX(active_learners)/MAX(ly_active_learners)-1)*100 as yoy_growth
FROM (
  SELECT
    SUM(1) AS active_learners,
  FROM (
    SELECT
      kaid,
    FROM
      TABLE_DATE_RANGE(core.learning_time_,
         DATE_ADD( USEC_TO_TIMESTAMP( NOW() ),-1-28,'DAY' ) ,
        DATE_ADD( USEC_TO_TIMESTAMP( NOW() ),-1,'DAY' ))
    WHERE kaid IS NOT NULL
      AND product='library'
      AND (domain!='computing' OR domain IS NULL)
      AND activity IN ('video','exercise','article')
    GROUP BY kaid
    HAVING SUM(seconds)>=30
  )
),
(
  SELECT
    SUM(1) AS ly_active_learners,
  FROM (
    SELECT
      kaid,
    FROM
      TABLE_DATE_RANGE(core.learning_time_,
         DATE_ADD( USEC_TO_TIMESTAMP( NOW() ),-365-28,'DAY' ) ,
         DATE_ADD( USEC_TO_TIMESTAMP( NOW() ),-365,'DAY' ))
    WHERE kaid IS NOT NULL
      AND product='library'
      AND (domain!='computing' OR domain IS NULL)
      AND activity IN ('video','exercise','article')
    GROUP BY kaid
    HAVING SUM(seconds)>=30
    )
)
