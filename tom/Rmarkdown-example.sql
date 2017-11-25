# This isn't a very interesting query, just something to prove out using a query to drive an Rmarkdown report
SELECT STRFTIME_UTC_USEC(UTC_USEC_TO_WEEK(joined, 1), "%Y-%m-%d") AS week, COUNT(*)
FROM [latest.UserData]
GROUP BY week
