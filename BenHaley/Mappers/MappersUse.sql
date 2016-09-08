SELECT
  time.kaid AS kaid,
  start,
  minutes,
  language,
  user_data.user_email AS user_email,
  user_data.user_nickname AS user_nickname,
  user_data.is_parent AS is_parent,
  user_data.joined AS joined,
  coach_user_data.user_email AS coach_user_email,
  coach_user_data.user_nickname AS coach_user_nickname,
  coach_user_data.is_parent AS coach_is_parent,
  coach_user_data.joined AS coach_joined,
  COALESCE(mappers_teacher_categories.pilot_group, mappers_user_categories.pilot_group, 'uncategorized') AS pilot_group,
FROM
  [{{table_time}}] AS time
JOIN (
  SELECT
    kaid,
    user_email,
    user_nickname,
    is_parent,
    joined,
  FROM
    [latest.UserData]) AS user_data
ON
  time.kaid == user_data.kaid
LEFT JOIN
  [{{table_mcc}}] AS coach_relationships
ON
  time.kaid == coach_relationships.student_kaid
LEFT JOIN (
  SELECT
    kaid,
    user_email,
    user_nickname,
    is_parent,
    joined,
  FROM
    [latest.UserData]) AS coach_user_data
ON
  coach_relationships.coach_kaid == coach_user_data.kaid
LEFT JOIN (
  SELECT
    email,
    pilot_group,
  FROM
    [ben5.mappers_teacher_categories]
  GROUP BY
    email,
    pilot_group,
) AS mappers_teacher_categories
ON
  mappers_teacher_categories.email == coach_user_data.user_email
LEFT JOIN (
  SELECT
    email,
    pilot_group,
  FROM
    [ben5.mappers_teacher_categories]
  GROUP BY
    email,
    pilot_group,
) AS mappers_user_categories
ON
  mappers_user_categories.email == user_data.user_email
