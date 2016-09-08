SELECT
    kaid,
    MIN(start) AS start,
    seconds/60 AS minutes,
    language,
    DATE(start) as date,
FROM
    TABLE_QUERY(core, 'table_id CONTAINS "learning_time"')
WHERE
    domain CONTAINS 'mappers'
    OR subject CONTAINS 'mappers'
    OR topic CONTAINS 'mappers'
    OR tutorial CONTAINS 'mappers'
GROUP BY
    kaid,
    minutes,
    language,
    date
