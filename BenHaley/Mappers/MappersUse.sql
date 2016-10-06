SELECT
  // Use info
  time.kaid AS kaid,
  start,
  minutes,
  language,

  // User stats
  user_data.user AS user,
  user_data.user_email AS user_email,
  user_data.user_email_domain AS user_email_domain,
  user_data.user_nickname AS user_nickname,
  user_data.is_parent AS is_parent,
  user_data.joined AS joined,
  CONCAT(
    STRING(YEAR(user_data.joined)),
    ' Q',
    STRING(QUARTER(user_data.joined))
  ) AS quarter_joined,
  mappers_topics.user_kaid AS kaid_with_recommendations,
  mappers_topics.user_kaid IS NOT NULL AS has_recommendations,

  // Coach stats
  coach_user_data.coach AS coach,
  coach_user_data.user_email AS coach_user_email,
  coach_user_data.user_email_domain AS coach_user_email_domain,
  coach_user_data.user_nickname AS coach_user_nickname,
  coach_user_data.is_parent AS coach_is_parent,
  coach_user_data.joined AS coach_joined,
  CONCAT(
    STRING(YEAR(coach_user_data.joined)),
    ' Q',
    STRING(QUARTER(coach_user_data.joined))
  ) AS coach_quarter_joined,

  // Student stats
  IFNULL(number_of_students_with_recommendations.n, 0) AS students_with_recommendations,

  // Group stats
  // Defer to coach value but use the student value.
  // Especially useful for cases where the coaach is taking and action.
  COALESCE(mappers_coach_categories.pilot_group, mappers_user_categories.pilot_group, 'uncategorized') AS pilot_group,
  COALESCE(coach_user_data.user_email_domain, user_data.user_email_domain) AS email_domain,
  COALESCE(coach_user_data.user_email, user_data.user_email) AS email,

FROM
  [ben5.mappers_time] AS time
JOIN (
  SELECT
    COALESCE(user_email, kaid) AS user,
    kaid,
    user_email,
    REGEXP_EXTRACT(user_email, '@(.*)') AS user_email_domain,
    user_nickname,
    is_parent,
    joined,
  FROM
    [latest.UserData]) AS user_data
ON
  time.kaid == user_data.kaid
LEFT JOIN
  ben5.most_coachy_coach AS coach_relationships
ON
  time.kaid == coach_relationships.student_kaid
LEFT JOIN (
  SELECT
    kaid,
    COALESCE(user_email, kaid) AS coach,
    user_email,
    REGEXP_EXTRACT(user_email, '@(.*)') AS user_email_domain,
    user_nickname,
    is_parent,
    joined,
  FROM
    [latest.UserData]) AS coach_user_data
ON
  coach_relationships.coach_kaid == coach_user_data.kaid
LEFT JOIN (
  SELECT
    user,
    pilot_group,
  FROM
    [ben5.mappers_pilot_categories]
  GROUP BY
    user,
    pilot_group,
) AS mappers_coach_categories
ON
  mappers_coach_categories.user == coach_user_data.coach
LEFT JOIN (
  SELECT
    user,
    pilot_group,
  FROM
    [ben5.mappers_pilot_categories]
  GROUP BY
    user,
    pilot_group,
) AS mappers_user_categories
ON
  mappers_user_categories.user == user_data.user
LEFT JOIN
  [ben5.number_of_students_with_recommendations] AS number_of_students_with_recommendations
ON
  time.kaid == number_of_students_with_recommendations.coach_kaid
LEFT JOIN
  [latest.MappersTopics] AS mappers_topics
ON
  mappers_topics.user_kaid == time.kaid
WHERE
  language == 'en'