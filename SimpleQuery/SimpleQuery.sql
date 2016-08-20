SELECT
  date,
  SUM(minutes)
FROM (
  /* table of TLT by day */
  SELECT
    DATE(start) AS date,
    SUM(seconds) / 60 AS minutes
  FROM
    TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
  GROUP BY
    date
)
GROUP BY
  date
ORDER BY
  date ASC
