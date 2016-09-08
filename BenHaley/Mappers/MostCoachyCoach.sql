SELECT
    student AS student_kaid,
    coach AS coach_kaid,
FROM (
    SELECT
      FIRST_VALUE(coach_relationships.student_kaid) OVER (PARTITION BY student_kaid ORDER BY n_students DESC) AS student,
      FIRST_VALUE(coach_relationships.coach_kaid) OVER (PARTITION BY student_kaid ORDER BY n_students DESC) AS coach,
    FROM
      [latest_derived.coach_relationships] AS coach_relationships
    JOIN (
      SELECT
        coach_kaid,
        COUNT(*) AS n_students
      FROM
        [latest_derived.coach_relationships]
      GROUP BY
        coach_kaid
      ORDER BY
        n_students) AS n_students
    ON
      coach_relationships.coach_kaid == n_students.coach_kaid)
GROUP BY
    student_kaid,
    coach_kaid
