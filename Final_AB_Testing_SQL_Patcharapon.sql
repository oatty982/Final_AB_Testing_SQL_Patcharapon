-- 1. Data Quality Check

-- We are running an experiment at an item-level, which means all users who visit will see the same page, but the layout of different item pages may differ.
-- Compare this table to the assignment events we captured for user_level_testing.
-- Does this table have everything you need to compute metrics like 30-day view-binary?

-- Answer: No, we need the eventime

-- 2. Reformat the Data

-- Reformat the final_assignments_qa to look like the final_assignments table, filling in any missing values with a placeholder of the appropriate data type.

-- Check null 1
SELECT 
  * 
FROM 
  dsv1069.final_assignments_qa
WHERE test_a IS NULL
or  test_b IS NULL
or  test_c IS NULL
or  test_d IS NULL
or  test_e IS NULL
or  test_f IS NULL

-- Check null 2
SELECT 
  item_id, COUNT(*)
FROM 
  dsv1069.final_assignments_qa
GROUP BY 
  item_id
HAVING 
  COUNT(*) > 1

-- Check null 3
SELECT 
  *
FROM 
  dsv1069.final_assignments_qa
WHERE 
  test_a NOT IN (0, 1)
OR 
  test_b NOT IN (0, 1)
OR 
  test_c NOT IN (0, 1)
OR 
  test_d NOT IN (0, 1)
OR 
  test_e NOT IN (0, 1)
OR 
  test_f NOT IN (0, 1)

WITH reshaped_data AS (
  SELECT item_id,
         test_a AS test_assignment,
         (CASE
              WHEN test_a IS NOT NULL then 'test_a'
              ELSE NULL
          END) AS test_number,
         (CASE
              WHEN test_a IS NOT NULL then '2013-01-05 00:00:00'
              ELSE NULL
          END) AS test_start_date
  FROM dsv1069.final_assignments_qa
  UNION
  SELECT item_id,
         test_b AS test_assignment,
         (CASE
              WHEN test_b IS NOT NULL then 'test_b'
              ELSE NULL
          END) AS test_number,
         (CASE
              WHEN test_b IS NOT NULL then '2013-01-05 00:00:00'
              ELSE NULL
          END) AS test_start_date
  FROM dsv1069.final_assignments_qa
  UNION
  SELECT item_id,
         test_c AS test_assignment,
         (CASE
              WHEN test_c IS NOT NULL then 'test_c'
              ELSE NULL
          END) AS test_number,
         (CASE
              WHEN test_c IS NOT NULL then '2013-01-05 00:00:00'
              ELSE NULL
          END) AS test_start_date
  FROM dsv1069.final_assignments_qa
  UNION
  SELECT item_id,
         test_d AS test_assignment,
         (CASE
              WHEN test_d IS NOT NULL then 'test_d'
              ELSE NULL
          END) AS test_number,
         (CASE
              WHEN test_d IS NOT NULL then '2013-01-05 00:00:00'
              ELSE NULL
          END) AS test_start_date
  FROM dsv1069.final_assignments_qa
  UNION
  SELECT item_id,
         test_e AS test_assignment,
         (CASE
              WHEN test_e IS NOT NULL then 'test_e'
              ELSE NULL
          END) AS test_number,
         (CASE
              WHEN test_e IS NOT NULL then '2013-01-05 00:00:00'
              ELSE NULL
          END) AS test_start_date
  FROM dsv1069.final_assignments_qa
  UNION
  SELECT item_id,
         test_f AS test_assignment,
         (CASE
              WHEN test_f IS NOT NULL then 'test_f'
              ELSE NULL
          END) AS test_number,
         (CASE
              WHEN test_f IS NOT NULL then '2013-01-05 00:00:00'
              ELSE NULL
          END) AS test_start_date
  FROM dsv1069.final_assignments_qa
)
SELECT *
FROM reshaped_data

-- 3. Compute Order Binary

-- Use this table to 
-- compute order_binary for the 30 day window after the test_start_date
-- for the test named item_test_2

SELECT 
 *
FROM 
  dsv1069.final_assignments

SELECT distinct test_number
FROM dsv1069.final_assignments

-- item_test_1
-- item_test_3
-- item_test_2

SELECT
  test_assignment,
  COUNT(DISTINCT item_id) AS item,
  SUM(order_binary_30d) AS order_binary_30d
FROM
(
  SELECT 
    f.item_id,
    f.test_assignment,
    f.test_number,
    MAX(CASE WHEN orders.created_at > f.test_start_date AND
    DATE_PART('day', orders.created_at - f.test_start_date) <= 30 
    THEN 1 ELSE 0 END) AS order_binary_30d
  FROM 
    dsv1069.final_assignments AS f
  LEFT JOIN 
    dsv1069.orders AS orders
  ON 
    f.item_id = orders.item_id
  WHERE 
    test_number = 'item_test_2'
  GROUP BY
    f.item_id,
    f.test_assignment,
    f.test_number
) item_test_2
GROUP BY test_assignment;

3. SubQuery

SELECT 
  f.item_id,
  f.test_assignment,
  f.test_number,
  MAX(CASE WHEN orders.created_at > f.test_start_date AND
  DATE_PART('day', orders.created_at - f.test_start_date) <= 30 
  THEN 1 ELSE 0 END) AS order_binary_30d
FROM 
  dsv1069.final_assignments AS f
LEFT JOIN 
  dsv1069.orders AS orders
ON 
  f.item_id = orders.item_id
WHERE 
  test_number = 'item_test_2'
GROUP BY
  f.item_id,
  f.test_assignment,
  f.test_number


-- 4. Compute View Item Metrics

-- Use this table to 
-- compute view_binary for the 30 day window after the test_start_date
-- for the test named item_test_2

SELECT
  test_assignment,
  COUNT(DISTINCT item_id) AS item,
  SUM(view_binary_30d) AS view_binary_30d
FROM
(
  SELECT 
    f.item_id,
    f.test_assignment,
    f.test_number,
    MAX(CASE WHEN views.event_time > f.test_start_date AND
    DATE_PART('day', views.event_time - f.test_start_date) <= 30 
    THEN 1 ELSE 0 END) AS view_binary_30d
  FROM 
    dsv1069.final_assignments AS f
  LEFT JOIN 
    dsv1069.view_item_events AS views
  ON 
    f.item_id = views.item_id
  WHERE 
    test_number = 'item_test_2'
  GROUP BY
    f.item_id,
    f.test_assignment,
    f.test_number
) item_test_2
GROUP BY test_assignment;

SELECT
  test_assignment,
  COUNT(DISTINCT item_id) AS item,
  SUM(view_binary_30d) AS view_binary_30d,
  CAST(100*SUM(view_binary_30d)/COUNT(item_id) AS FLOAT) AS viewed_percent,
  SUM(views) AS views,
  SUM(views)/COUNT(item_id) AS average_views_per_item
FROM
(
  SELECT 
    f.item_id,
    f.test_assignment,
    f.test_number,
    MAX(CASE WHEN views.event_time > f.test_start_date AND
    DATE_PART('day', views.event_time - f.test_start_date) <= 30 
    THEN 1 ELSE 0 END) AS view_binary_30d,
    COUNT(views.event_id) AS views
  FROM 
    dsv1069.final_assignments AS f
  LEFT OUTER JOIN 
    (
    SELECT 
      event_time,
      event_id,
      CAST(parameter_value AS INT) AS item_id
    FROM 
      dsv1069.events 
    WHERE 
      event_name = 'view_item'
    AND 
      parameter_name = 'item_id'
    ) views
  ON 
    f.item_id = views.item_id
  WHERE 
    test_number = 'item_test_2'
  GROUP BY
    f.item_id,
    f.test_assignment,
    f.test_number
) item_test_2
GROUP BY test_assignment;


-- another one

SELECT
test_assignment,
COUNT(item_id) AS items,
SUM(view_binary_30d) AS viewed_items,
CAST(100*SUM(view_binary_30d)/COUNT(item_id) AS FLOAT) AS viewed_percent,
SUM(views) AS views,
SUM(views)/COUNT(item_id) AS average_views_per_item
FROM 
(
 SELECT 
   fa.test_assignment,
   fa.item_id, 
   MAX(CASE WHEN views.event_time > fa.test_start_date THEN 1 ELSE 0 END)  AS view_binary_30d,
   COUNT(views.event_id) AS views
  FROM 
    dsv1069.final_assignments fa
    
  LEFT OUTER JOIN 
    (
    SELECT 
      event_time,
      event_id,
      CAST(parameter_value AS INT) AS item_id
    FROM 
      dsv1069.events 
    WHERE 
      event_name = 'view_item'
    AND 
      parameter_name = 'item_id'
    ) views
  ON 
    fa.item_id = views.item_id
  AND 
    views.event_time >= fa.test_start_date
  AND 
    DATE_PART('day', views.event_time - fa.test_start_date ) <= 30
  WHERE 
    fa.test_number= 'item_test_2'
  GROUP BY
    fa.test_assignment,
    fa.item_id
) item_level
GROUP BY 
 test_assignment


-- 5. Compute lift and p-value

--Use the https://thumbtack.github.io/abba/demo/abba.html to compute the lifts in metrics and the p-values for the binary metrics ( 30 day order binary and 30 day view binary) using a interval 95% confidence.

-- For orders:  lift is -14% – 12% (-1%) and pval is 0.88
-- For views:   lift is -1.6% – 6.1% (2.3%) and pval is 0.25