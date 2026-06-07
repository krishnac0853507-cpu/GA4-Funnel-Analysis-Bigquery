-- Query 1: Dataset Overview
SELECT COUNT(*) AS event_count,
       COUNT(DISTINCT user_pseudo_id) AS user_count,
       COUNT(DISTINCT event_date) AS day_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;







-- Query 2: Event Types
SELECT
  event_name,
  COUNT(*) AS event_count
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY event_name
ORDER BY event_count DESC;







-- Query 3: Date Range
SELECT
  MIN(event_date) AS start_date,
  MAX(event_date) AS end_date,
  COUNT(DISTINCT event_date) AS total_days,
  COUNT(DISTINCT user_pseudo_id) AS total_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;









-- Query 4: Core Funnel
WITH raw_funnel AS (
  SELECT
    user_pseudo_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN (
    'session_start',
    'view_item',
    'add_to_wishlist',
    'add_to_cart',
    'begin_checkout',
    'purchase'
  )
),

user_funnel AS (
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN event_name = 'session_start'   THEN 1 ELSE 0 END) AS visited,
    MAX(CASE WHEN event_name = 'view_item'        THEN 1 ELSE 0 END) AS viewed_product,
    MAX(CASE WHEN event_name = 'add_to_wishlist'  THEN 1 ELSE 0 END) AS wishlisted,
    MAX(CASE WHEN event_name = 'add_to_cart'      THEN 1 ELSE 0 END) AS added_to_cart,
    MAX(CASE WHEN event_name = 'begin_checkout'   THEN 1 ELSE 0 END) AS checkout,
    MAX(CASE WHEN event_name = 'purchase'         THEN 1 ELSE 0 END) AS purchased
  FROM raw_funnel
  GROUP BY user_pseudo_id
)

SELECT
  COUNT(*)                                               AS total_users,
  SUM(visited)                                           AS stage_1_visited,
  SUM(viewed_product)                                    AS stage_2_viewed,
  SUM(wishlisted)                                        AS stage_3_wishlist,
  SUM(added_to_cart)                                     AS stage_4_cart,
  SUM(checkout)                                          AS stage_5_checkout,
  SUM(purchased)                                         AS stage_6_purchased,
  ROUND(SUM(viewed_product) * 100.0 / COUNT(*), 2)       AS pct_viewed,
  ROUND(SUM(wishlisted)     * 100.0 / COUNT(*), 2)       AS pct_wishlist,
  ROUND(SUM(added_to_cart)  * 100.0 / COUNT(*), 2)       AS pct_cart,
  ROUND(SUM(checkout)       * 100.0 / COUNT(*), 2)       AS pct_checkout,
  ROUND(SUM(purchased)      * 100.0 / COUNT(*), 2)       AS pct_purchased
FROM user_funnel;









-- Query 5:Dropoff
WITH raw_funnel AS (
  SELECT
    user_pseudo_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN (
    'session_start','view_item',
    'add_to_wishlist','add_to_cart',
    'begin_checkout','purchase'
  )
),

user_funnel AS (
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN event_name = 'session_start'  THEN 1 ELSE 0 END) AS visited,
    MAX(CASE WHEN event_name = 'view_item'       THEN 1 ELSE 0 END) AS viewed,
    MAX(CASE WHEN event_name = 'add_to_wishlist' THEN 1 ELSE 0 END) AS wishlisted,
    MAX(CASE WHEN event_name = 'add_to_cart'     THEN 1 ELSE 0 END) AS carted,
    MAX(CASE WHEN event_name = 'begin_checkout'  THEN 1 ELSE 0 END) AS checkout,
    MAX(CASE WHEN event_name = 'purchase'        THEN 1 ELSE 0 END) AS purchased
  FROM raw_funnel
  GROUP BY user_pseudo_id
),

stage_counts AS (
  SELECT
    SUM(visited)    AS s1,
    SUM(viewed)     AS s2,
    SUM(wishlisted) AS s3,
    SUM(carted)     AS s4,
    SUM(checkout)   AS s5,
    SUM(purchased)  AS s6
  FROM user_funnel
)

SELECT
  ROUND((s1 - s2) * 100.0 / NULLIF(s1,0),2) AS dropoff_visit_to_view,
  ROUND((s2 - s3) * 100.0 / NULLIF(s2,0),2) AS dropoff_view_to_wishlist,
  ROUND((s3 - s4) * 100.0 / NULLIF(s3,0),2) AS dropoff_wishlist_to_cart,
  ROUND((s4 - s5) * 100.0 / NULLIF(s4,0),2) AS dropoff_cart_to_checkout,
  ROUND((s5 - s6) * 100.0 / NULLIF(s5,0),2) AS dropoff_checkout_to_purchase
FROM stage_counts;












-- Query 6: User Journey
WITH funnel_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    ROW_NUMBER() OVER (
      PARTITION BY user_pseudo_id
      ORDER BY event_timestamp
    ) AS step_number,
    LAG(event_name) OVER (
      PARTITION BY user_pseudo_id
      ORDER BY event_timestamp
    ) AS previous_event
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN (
    'session_start','view_item',
    'add_to_wishlist','add_to_cart',
    'begin_checkout','purchase'
  )
)

SELECT
  previous_event,
  event_name AS current_event,
  COUNT(*) AS transition_count,
  ROUND(COUNT(*) * 100.0 /
    SUM(COUNT(*)) OVER (PARTITION BY previous_event), 2) AS transition_pct
FROM funnel_events
WHERE previous_event IS NOT NULL
GROUP BY previous_event, current_event
ORDER BY previous_event, transition_count DESC;














-- Query 7: Device Funnel
WITH base_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    device.category AS device_type
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN (
    'session_start','view_item',
    'add_to_cart','purchase'
  )
),

user_funnel AS (
  SELECT
    user_pseudo_id,
    MAX(device_type) AS device_type,
    MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS visited,
    MAX(CASE WHEN event_name = 'view_item'     THEN 1 ELSE 0 END) AS viewed,
    MAX(CASE WHEN event_name = 'add_to_cart'   THEN 1 ELSE 0 END) AS carted,
    MAX(CASE WHEN event_name = 'purchase'      THEN 1 ELSE 0 END) AS purchased
  FROM base_events
  GROUP BY user_pseudo_id
)

SELECT
  device_type,
  COUNT(*)                                          AS total_users,
  SUM(visited)                                      AS visited,
  SUM(viewed)                                       AS viewed,
  SUM(carted)                                       AS carted,
  SUM(purchased)                                    AS purchased,
  ROUND(SUM(purchased) * 100.0 / COUNT(*), 2)       AS conversion_rate
FROM user_funnel
GROUP BY device_type
ORDER BY conversion_rate DESC;













-- Query 8: Cohorot
WITH first_visit AS (
  SELECT
    user_pseudo_id,
    FORMAT_DATE('%Y-%m',
      MIN(PARSE_DATE('%Y%m%d', event_date))) AS cohort_month
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'session_start'
  GROUP BY user_pseudo_id
),

purchases AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'
)

SELECT
  f.cohort_month,
  COUNT(DISTINCT f.user_pseudo_id)                   AS total_users,
  COUNT(DISTINCT p.user_pseudo_id)                   AS converted_users,
  ROUND(COUNT(DISTINCT p.user_pseudo_id) * 100.0 /
    COUNT(DISTINCT f.user_pseudo_id), 2)             AS conversion_rate
FROM first_visit f
LEFT JOIN purchases p
  ON f.user_pseudo_id = p.user_pseudo_id
GROUP BY cohort_month
ORDER BY cohort_month;