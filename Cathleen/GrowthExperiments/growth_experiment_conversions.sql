# Create a uniform data record for conversions
## Destination: cathleen.growth_experiment_conversions
SELECT
 start_time,
 bingo_id,
 conversions.conversion as conversion,
 device,
 language,
 app,
 CASE WHEN registration_date < start_time
   AND registration_date IS NOT NULL THEN TRUE
   ELSE FALSE END as registered,
 CASE WHEN product IS NOT NULL THEN product
   # convert path for pageview uri into product
   WHEN uri_domain = 'mission' THEN uri_domain
   WHEN uri_domain = 'computer-programming' THEN uri_domain
   WHEN uri_domain = 'sat' THEN uri_domain
   WHEN uri_domain IS NOT NULL THEN 'library'
   # convert content id for article scroll into product
   WHEN topic_tree.domain = 'test-prep' THEN topic_tree.domain
   ELSE 'library' END as product,
CASE WHEN conversions.domain IS NOT NULL THEN conversions.domain
  WHEN uri_domain = 'mission' THEN 'math'
  WHEN uri_domain IS NOT NUll THEN uri_domain
  # for video_started and problem_attempt
  WHEN mission IS NOT NULL THEN 'math'
  ELSE topic_tree.domain END as domain
FROM (
 FLATTEN(
   SELECT
     start_time_timestamp as start_time,
     bingo_conversion_events.bingo_id as bingo_id,
     elog_user_kaid as kaid,
     bingo_conversion_events.conversion as conversion,
     elog_device_type as device,
     elog_language as language,
     elog_KA_APP as app,
     #elog_user_is_registered as registered,
     REGEXP_REPLACE(
       IFNULL( JSON_EXTRACT(bingo_conversion_events.extra,'$.Product'),
         JSON_EXTRACT(bingo_conversion_events.extra,'$.product')),
          '\"','') as product,
     REGEXP_EXTRACT(
       REGEXP_REPLACE(
           IFNULL( JSON_EXTRACT(bingo_conversion_events.extra,'$.path'),
             JSON_EXTRACT(bingo_conversion_events.extra,'$.tab_url')),
          '\"',''),
       r'/(?:[^/]*/){0}([^/]*)') as uri_domain,
     REGEXP_REPLACE(
       JSON_EXTRACT(bingo_conversion_events.extra, '$.content_id'),
       '\"','') as content_id,
     REGEXP_REPLACE(
       JSON_EXTRACT(bingo_conversion_events.extra, '$.Domain'),
       '\"','') as domain,
     REGEXP_REPLACE(
       JSON_EXTRACT(bingo_conversion_events.extra, '$.Mission'),
       '\"','') as mission,
   # limit date range from the beginning of experiments
   FROM  TABLE_DATE_RANGE(logs.requestlogs_,
       TIMESTAMP('2016-08-30'),
       USEC_TO_TIMESTAMP(NOW()))
   WHERE bingo_conversion_events.conversion IN (
       'pageview',
       'pageview_subject',
       'pageview_concept',
       'pageview_exercise',
       'pageview_video',
       'article_view',
       'video_started',
       'video_completed',
       'problem_attempt',
       'return_visit',
       'article_scroll')
   , content_id)
)  as  conversions
LEFT JOIN latest.UserData ud
 on conversions.kaid = ud.kaid
LEFT JOIN latest_content.topic_tree topic_tree
 ON conversions.content_id = topic_tree.id
