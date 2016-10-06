SELECT
  COUNT(DISTINCT mappers_topics.user_kaid) AS n,
  coach_kaid,
FROM
  [ben5.most_coachy_coach] as coach_relationships
JOIN
  [latest.MappersTopics] AS mappers_topics
ON
  mappers_topics.user_kaid == coach_relationships.student_kaid
GROUP BY
  coach_kaid