SELECT bingo_conversion_events.conversion AS Conversion, COUNT(*) AS Count
FROM TABLE_DATE_RANGE(logs.requestlogs_,
  DATE_ADD(TIMESTAMP(CURRENT_DATE()), -1, "DAY"),
  DATE_ADD(TIMESTAMP(CURRENT_DATE()), -1, "DAY"))
WHERE bingo_conversion_events.conversion IS NOT NULL
GROUP BY Conversion
ORDER BY Count DESC
LIMIT 12
