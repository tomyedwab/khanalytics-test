# populate: datastudio_dashboards.library_lt_by_segments
# learning time trend cut by platform, country/language, classroom, domain, and subjects
SELECT
    STRFTIME_UTC_USEC(start, "%Y%m%d") as date_format,
    STRFTIME_UTC_USEC(start, "%Y%m") as month,
    device,
    ka_app as app,
    country,
    language,
    domain,
    subject,
    (CASE WHEN classroom.student_kaid IS NOT NULL THEN TRUE
        ELSE FALSE END) as in_classroom,
    SUM(seconds)/60 as minutes
FROM (
    SELECT
        start,
        kaid,
        device,
        ka_app,
        country,
        language,
        domain,
        subject,
        seconds
    FROM TABLE_QUERY(core, "table_id CONTAINS 'learning_time'")
      WHERE product = 'library'
       AND (domain!= 'computing'
          OR domain IS NULL)
    ) as lt
    # join to coach data
LEFT JOIN (
  /* table of all teacher coached students */
    SELECT
      student_kaid,
      MAX(user_segments.is_teacher) AS teacher_coached
    FROM (
      SELECT
        *
      FROM
        latest_derived.coach_relationships,
        TABLE_QUERY(educator_archive, "table_id CONTAINS 'coach_relationships'")
      GROUP BY
        student_kaid, coach_kaid
    ) AS coach_relationships
    INNER JOIN
      latest_derived.user_segments AS user_segments
    ON
      coach_relationships.coach_kaid = user_segments.kaid
    GROUP BY
      student_kaid
    HAVING teacher_coached IS TRUE
) as classroom
    ON classroom.student_kaid = lt.kaid
GROUP BY  date_format, month,  device, app, country, language, in_classroom, domain, subject

