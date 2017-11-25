# >> tomyedwab.content_tools_metrics_final
SELECT
  publish.week AS week,
  publish.en_publish_attempts AS en_publish_attempts,
  publish.en_publish_failures AS en_publish_failures,
  publish.en_publish_retries AS en_publish_retries,
  publish.en_publish_minutes_p5 AS en_publish_minutes_p5,
  publish.en_publish_minutes_q1 AS en_publish_minutes_q1,
  publish.en_publish_minutes_median AS en_publish_minutes_median,
  publish.en_publish_minutes_q3 AS en_publish_minutes_q3,
  publish.en_publish_minutes_p95 AS en_publish_minutes_p95,
  publish.en_publish_total_p5 AS en_publish_total_p5,
  publish.en_publish_total_q1 AS en_publish_total_q1,
  publish.en_publish_total_median AS en_publish_total_median,
  publish.en_publish_total_q3 AS en_publish_total_q3,
  publish.en_publish_total_p95 AS en_publish_total_p95,
  publish.intl_publish_attempts AS intl_publish_attempts,
  publish.intl_publish_failures AS intl_publish_failures,
  publish.intl_publish_retries AS intl_publish_retries,
  publish.intl_publish_minutes_p5 AS intl_publish_minutes_p5,
  publish.intl_publish_minutes_q1 AS intl_publish_minutes_q1,
  publish.intl_publish_minutes_median AS intl_publish_minutes_median,
  publish.intl_publish_minutes_q3 AS intl_publish_minutes_q3,
  publish.intl_publish_minutes_p95 AS intl_publish_minutes_p95,
  publish.intl_publish_total_p5 AS intl_publish_total_p5,
  publish.intl_publish_total_q1 AS intl_publish_total_q1,
  publish.intl_publish_total_median AS intl_publish_total_median,
  publish.intl_publish_total_q3 AS intl_publish_total_q3,
  publish.intl_publish_total_p95 AS intl_publish_total_p95,
  edit.create_secs_p5 AS create_secs_p5,
  edit.create_secs_q1 AS create_secs_q1,
  edit.create_secs_median AS create_secs_median,
  edit.create_secs_q3 AS create_secs_q3,
  edit.create_secs_p95 AS create_secs_p95,
  edit.create_attempts AS create_attempts,
  edit.create_validation_errors AS create_validation_errors,
  edit.create_server_errors AS create_failures,
  edit.edit_secs_p5 AS edit_secs_p5,
  edit.edit_secs_q1 AS edit_secs_q1,
  edit.edit_secs_median AS edit_secs_median,
  edit.edit_secs_q3 AS edit_secs_q3,
  edit.edit_secs_p95 AS edit_secs_p95,
  edit.edit_attempts AS edit_attempts,
  edit.edit_validation_errors AS edit_validation_errors,
  edit.edit_server_errors AS edit_failures,
  edit.load_secs_p5 AS load_secs_p5,
  edit.load_secs_q1 AS load_secs_q1,
  edit.load_secs_median AS load_secs_median,
  edit.load_secs_q3 AS load_secs_q3,
  edit.load_secs_p95 AS load_secs_p95,
  edit.load_attempts AS load_attempts,
  edit.load_validation_errors AS load_validation_errors,
  edit.load_server_errors AS load_failures,
  load.article_secs_p5 AS article_secs_p5,
  load.article_secs_q1 AS article_secs_q1,
  load.article_secs_median AS article_secs_median,
  load.article_secs_q3 AS article_secs_q3,
  load.article_secs_p95 AS article_secs_p95,
  load.article_loads AS article_page_attempts,
  load.article_server_errors AS article_page_failures,
  load.exercise_secs_p5 AS exercise_secs_p5,
  load.exercise_secs_q1 AS exercise_secs_q1,
  load.exercise_secs_median AS exercise_secs_median,
  load.exercise_secs_q3 AS exercise_secs_q3,
  load.exercise_secs_p95 AS exercise_secs_p95,
  load.exercise_loads AS exercise_page_attempts,
  load.exercise_server_errors AS exercise_page_failures,
  exercises.load_secs_p5 AS exercise_load_secs_p5,
  exercises.load_secs_q1 AS exercise_load_secs_q1,
  exercises.load_secs_median AS exercise_load_secs_median,
  exercises.load_secs_q3 AS exercise_load_secs_q3,
  exercises.load_secs_p95 AS exercise_load_secs_p95,
  exercises.load_attempts AS exercise_load_attempts,
  exercises.load_server_errors AS exercise_load_failures,
  exercises.item_save_secs_p5 AS item_save_secs_p5,
  exercises.item_save_secs_q1 AS item_save_secs_q1,
  exercises.item_save_secs_median AS item_save_secs_median,
  exercises.item_save_secs_q3 AS item_save_secs_q3,
  exercises.item_save_secs_p95 AS item_save_secs_p95,
  exercises.item_save_attempts AS item_save_attempts,
  exercises.item_save_server_errors AS item_save_failures,
  start_publish.cmspub_secs_p5 AS cmspub_secs_p5,
  start_publish.cmspub_secs_q1 AS cmspub_secs_q1,
  start_publish.cmspub_secs_median AS cmspub_secs_median,
  start_publish.cmspub_secs_q3 AS cmspub_secs_q3,
  start_publish.cmspub_secs_p95 AS cmspub_secs_p95,
  start_publish.cmspub_attempts AS cmspub_attempts,
  start_publish.cmspub_server_errors AS cmspub_failures,
  start_publish.new_publish_start_secs_p5 AS new_publish_start_secs_p5,
  start_publish.new_publish_start_secs_q1 AS new_publish_start_secs_q1,
  start_publish.new_publish_start_secs_median AS new_publish_start_secs_median,
  start_publish.new_publish_start_secs_q3 AS new_publish_start_secs_q3,
  start_publish.new_publish_start_secs_p95 AS new_publish_start_secs_p95,
  start_publish.new_publish_start_attempts AS new_publish_start_attempts,
  start_publish.new_publish_start_server_errors AS new_publish_start_failures,
  start_publish.old_publish_start_secs_p5 AS old_publish_start_secs_p5,
  start_publish.old_publish_start_secs_q1 AS old_publish_start_secs_q1,
  start_publish.old_publish_start_secs_median AS old_publish_start_secs_median,
  start_publish.old_publish_start_secs_q3 AS old_publish_start_secs_q3,
  start_publish.old_publish_start_secs_p95 AS old_publish_start_secs_p95,
  start_publish.old_publish_start_attempts AS old_publish_start_attempts,
  start_publish.old_publish_start_server_errors AS old_publish_start_failures,
  start_publish.old_publish_load_secs_p5 AS old_publish_load_secs_p5,
  start_publish.old_publish_load_secs_q1 AS old_publish_load_secs_q1,
  start_publish.old_publish_load_secs_median AS old_publish_load_secs_median,
  start_publish.old_publish_load_secs_q3 AS old_publish_load_secs_q3,
  start_publish.old_publish_load_secs_p95 AS old_publish_load_secs_p95,
  start_publish.old_publish_load_attempts AS old_publish_load_attempts,
  start_publish.old_publish_load_server_errors AS old_publish_load_failures

FROM [{publish_table}] publish

LEFT JOIN (
    SELECT a.week AS week,
        create_secs_p5, create_secs_q1, create_secs_median,
        create_secs_q3, create_secs_p95, create_attempts,
        create_validation_errors, create_server_errors,
        edit_secs_p5, edit_secs_q1, edit_secs_median,
        edit_secs_q3, edit_secs_p95, edit_attempts,
        edit_validation_errors, edit_server_errors,
        load_secs_p5, load_secs_q1, load_secs_median,
        load_secs_q3, load_secs_p95, load_attempts,
        load_validation_errors, load_server_errors
    FROM [{revisions_incr_table}] a
    INNER JOIN (
        SELECT week, MAX(query_time) AS max_query_time
    FROM [{revisions_incr_table}]
    GROUP BY week) b
    ON a.week = b.week AND a.query_time = b.max_query_time) edit

ON publish.week = edit.week

LEFT JOIN (
    SELECT a.week AS week,
        article_secs_p5, article_secs_q1, article_secs_median,
        article_secs_q3, article_secs_p95, article_loads,
        article_server_errors,
        exercise_secs_p5, exercise_secs_q1, exercise_secs_median,
        exercise_secs_q3, exercise_secs_p95, exercise_loads,
        exercise_server_errors
    FROM [{load_incr_table}] a
    INNER JOIN (
        SELECT week, MAX(query_time) AS max_query_time
    FROM [{load_incr_table}]
    GROUP BY week) b
    ON a.week = b.week AND a.query_time = b.max_query_time) load

ON publish.week = load.week

LEFT JOIN (
    SELECT a.week AS week,
        load_secs_p5, load_secs_q1, load_secs_median,
        load_secs_q3, load_secs_p95, load_attempts,
        load_server_errors,
        item_save_secs_p5, item_save_secs_q1, item_save_secs_median,
        item_save_secs_q3, item_save_secs_p95, item_save_attempts,
        item_save_server_errors
    FROM [{exercises_incr_table}] a
    INNER JOIN (
        SELECT week, MAX(query_time) AS max_query_time
    FROM [{exercises_incr_table}]
    GROUP BY week) b
    ON a.week = b.week AND a.query_time = b.max_query_time) exercises

ON publish.week = exercises.week

LEFT JOIN (
    SELECT a.week AS week,
        cmspub_secs_p5, cmspub_secs_q1, cmspub_secs_median,
        cmspub_secs_q3, cmspub_secs_p95, cmspub_attempts,
        cmspub_server_errors,
        new_publish_start_secs_p5, new_publish_start_secs_q1, new_publish_start_secs_median,
        new_publish_start_secs_q3, new_publish_start_secs_p95, new_publish_start_attempts,
        new_publish_start_server_errors,
        old_publish_start_secs_p5, old_publish_start_secs_q1, old_publish_start_secs_median,
        old_publish_start_secs_q3, old_publish_start_secs_p95, old_publish_start_attempts,
        old_publish_start_server_errors,
        old_publish_load_secs_p5, old_publish_load_secs_q1, old_publish_load_secs_median,
        old_publish_load_secs_q3, old_publish_load_secs_p95, old_publish_load_attempts,
        old_publish_load_server_errors
    FROM [{start_publish_incr_table}] a
    INNER JOIN (
        SELECT week, MAX(query_time) AS max_query_time
    FROM [{start_publish_incr_table}]
    GROUP BY week) b
    ON a.week = b.week AND a.query_time = b.max_query_time) start_publish

ON publish.week = start_publish.week

WHERE publish.week >= '2017-01-01'
