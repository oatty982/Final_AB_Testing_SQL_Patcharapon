SELECT
  (CASE 
    WHEN first_view IS NULL THEN FALSE
    ELSE TRUE END
  ) AS HAS_VIEWED_PROFILE_PAGE,
  COUNT(user_id) AS users
FROM (
    SELECT u.id AS user_id, MIN(e.event_time) AS first_view
    FROM dsv1069.users AS u
    LEFT OUTER JOIN dsv1069.events AS e ON e.user_id = u.id
    AND e.event_name = 'view_user_profile'
    GROUP BY u.id
) AS first_profile_views
GROUP BY HAS_VIEWED_PROFILE_PAGE;

-- Exercise 1:
-- Goal: Write a query to format the view_item event into a table with the appropriate columns

SELECT *
FROM dsv1069.events 
WHERE event_name = 'view_item';

-- Exercise 2:
-- Goal: Write a query to format the view_item event into a table with the appropriate columns
-- (This replicates what we had in the slides, but it is missing a column)

SELECT event_id, event_time, user_id, platform,
(CASE 
  WHEN parameter_name = 'item_id' THEN CAST(parameter_value AS INT)
  ELSE NULL
END) AS item_id
FROM dsv1069.events 
WHERE event_name = 'view_item'
ORDER BY event_id;

-- Exercise 3:
-- Goal: Use the result from the previous exercise, but make sure
-- Starter Code: (Ex#2)

SELECT event_id, event_time, user_id, platform,
(CASE 
  WHEN parameter_name = 'item_id' THEN CAST(parameter_value AS INT)
  ELSE NULL
END) AS item_id,
(CASE 
  WHEN parameter_name = 'referrer' THEN parameter_value
  ELSE NULL
END) AS referrer
FROM dsv1069.events 
WHERE event_name = 'view_item'
ORDER BY event_id;

--

SELECT 
  event_id, 
  event_time, 
  user_id, 
  platform,
  MAX(CASE 
    WHEN parameter_name = 'item_id' THEN CAST(parameter_value AS INT)
    ELSE NULL
  END) AS item_id,
  MAX(CASE 
    WHEN parameter_name = 'referrer' THEN parameter_value
    ELSE NULL
  END) AS referrer
FROM dsv1069.events 
WHERE event_name = 'view_item'
GROUP BY event_id, event_time, user_id, platform
ORDER BY event_id;

--
SELECT 
  date(event_time)  as date,
  COUNT(*)          as rows
FROM 
  dsv1069.events_201701
GROUP BY
  date(event_time)

--
SELECT 
  date(event_time)  as date,
  platform,
  COUNT(*)          as rows
FROM 
  dsv1069.events_201701
GROUP BY
  date(event_time),
  platform

--
SELECT * 
FROM dsv1069.orders
JOIN dsv1069.users ON orders.user_id = users.parent_user_id

SELECT COUNT(*)
FROM dsv1069.orders
JOIN dsv1069.users ON orders.user_id = users.parent_user_id

SELECT COUNT(*)
FROM dsv1069.orders
JOIN dsv1069.users ON orders.user_id = COALESCE(users.parent_user_id,users.id)

--
SELECT SUM(view_events)
FROM dsv1069.item_views_by_category_temp

--
SELECT 
  COUNT(distinct event_id) as event_count
FROM 
  dsv1069.events 
WHERE 
  event_name = 'view_item';

--
SELECT 
  DATE(event_time) AS date,
  COUNT(*) AS rows_count,
  COUNT(DISTINCT event_id) AS event_count,
  COUNT(DISTINCT user_id) AS user_count
FROM 
  dsv1069.events_ex2
GROUP BY
  DATE(event_time)

--
CREATE TABLE 
  view_item_event_1
AS
SELECT 
  event_id, 
  event_time, 
  user_id, 
  platform,
  MAX(CASE WHEN parameter_name = 'item_id' THEN CAST(parameter_value AS INT) END) AS item_id,
  MAX(CASE WHEN parameter_name = 'referrer' THEN parameter_value END) AS referrer
FROM dsv1069.events 
WHERE event_name = 'view_item'
GROUP BY 
  event_id, 
  event_time, 
  user_id, 
  platform
ORDER BY 
  event_id

--
DESCRIBE view_item_event_1;
SELECT * FROM view_item_event_1;
DROP TABLE view_item_event_1;

--
CREATE TABLE IF NOT EXISTS "view_item_event" (
    event_id    VARCHAR(32) NOT NULL PRIMARY KEY,
    event_time  VARCHAR(26),
    user_id     INT,
    platform    VARCHAR(10),
    item_id     INT,
    referrer    VARCHAR(17)
);

INSERT INTO "view_item_event" (
  event_id, 
  event_time, 
  user_id, 
  platform,
  item_id,
  referrer
)
SELECT 
  event_id, 
  event_time::TIMESTAMP, 
  user_id, 
  platform,
  MAX(CASE WHEN parameter_name = 'item_id' THEN parameter_value ELSE NULL END) AS item_id,
  MAX(CASE WHEN parameter_name = 'referrer' THEN parameter_value END) AS referrer
FROM dsv1069.events 
WHERE event_name = 'view_item'
GROUP BY 
  event_id, 
  event_time, 
  user_id, 
  platform
ORDER BY 
  event_id;

--
{% assign ds = '2018-01-01' %}

SELECT
  id,
  '{{ ds }}' AS variable_column
FROM dsv1069.users;

--
{% assign ds = '2018-01-01' %}

SELECT
  id,created_at
FROM 
  dsv1069.users
WHERE
  created_at  <= '{{ ds }}'

-- Data Engineering Questions:

-- How do you check that the table contains what you expect?

-- How do insert by day?

-- How do backfill the data
{% assign ds = '2018-01-01' %}

SELECT
  id                                                                                    AS user_id,
  CASE WHEN users.created_at::date = '{{ ds }}'::date THEN 1 ELSE 0 END                 AS created_today,
  CASE WHEN users.deleted_at::date <= '{{ ds }}'::date THEN 1 ELSE 0 END                AS is_deleted,
  CASE WHEN users.deleted_at::date = '{{ ds }}'::date THEN 1 ELSE 0 END                 AS is_deleted_today,
  CASE WHEN users_with_orders.user_id IS NOT NULL THEN 1 ELSE 0 END                     AS has_ever_ordered,
  CASE WHEN users_with_orders_today.user_id IS NOT NULL THEN 1 ELSE 0 END               AS ordered_today,
  '{{ ds }}'                                                                            AS date
FROM 
  dsv1069.users
LEFT OUTER JOIN
  (
  SELECT DISTINCT user_id
  FROM dsv1069.orders
  WHERE created_at::date <= '{{ ds }}'::date
  ) users_with_orders
ON
  users_with_orders.user_id = users.id
LEFT OUTER JOIN
  (
  SELECT DISTINCT user_id
  FROM dsv1069.orders
  WHERE created_at::date = '{{ ds }}'::date
  ) users_with_orders_today
ON
  users_with_orders_today.user_id = users.id

--

CREATE TABLE IF NOT EXISTS user_info
(
  user_id           INT(10) NOT NULL,
  created_today     INT(1)  NOT NULL,
  is_deleted        INT(1)  NOT NULL,
  is_deleted_today  INT(1)  NOT NULL,
  has_ever_ordered  INT(1)  NOT NULL,
  ordered_today     INT(1)  NOT NULL,
  ds                DATE    NOT NULL,
);

DESCRIBE user_info;

CREATE TABLE IF NOT EXISTS user_info
(
  user_id           INTEGER NOT NULL,
  created_today     INTEGER NOT NULL,
  is_deleted        INTEGER NOT NULL,
  is_deleted_today  INTEGER NOT NULL,
  has_ever_ordered  INTEGER NOT NULL,
  ordered_today     INTEGER NOT NULL,
  ds                DATE    NOT NULL
);


DESCRIBE user_info;

-- Partions: Changes
-- it can make update faster
-- it can make retrieval faster
-- it can make join faster

-- CREATE TABLE
CREATE TABLE items_orders 
(
  id                BIGINT,
  item_name         STRING,
  order_count       BIGINT,
  category          STRING,
)

CREATE TABLE items_orders 
(
  id                BIGINT,
  item_name         STRING,
  order_count       BIGINT
)
PARTITION BY
(
  category          STRING,
)

-- INSERT INTO TABLE
INSERT INTO TABLE
  items_orders
SELECT
  id,
  item_name,
  order_count,
  category
FROM ...

INSERT INTO TABLE
  items_orders
  (PARTITION category)
SELECT
  id,
  item_name,
  order_count,
  category
FROM ...

-- When to Partition: Example
-- Example: Partition by date

WHERE day >= date_add(CURDATE(), INTERVAL -1 MONTH)

--
SELECT
  dates_rollup.date,
  COALESCE(SUM(orders), 0)                      AS orders,
  COALESCE(SUM(items_ordered), 0)               AS items_ordered,
  COUNT(*)                                      AS row
FROM
  dsv1069.dates_rollup
LEFT OUTER JOIN
  (
    SELECT
      DATE(paid_at)                             AS day,
      COUNT(DISTINCT invoice_id)                AS orders,
      COUNT(DISTINCT line_item_id)              AS items_ordered
    FROM
      dsv1069.orders
    GROUP BY
      DATE(paid_at)
  ) daily_orders ON daily_orders.day = dates_rollup.date
GROUP BY
  dates_rollup.date;


--
SELECT 
  user_id,
  item_id,
  event_time,
  row_number() over (PARTITION BY user_id ORDER BY event_time DESC) AS row_number,
  RANK() over (PARTITION BY user_id ORDER BY event_time DESC) AS rank,
  DENSE_RANK() over (PARTITION BY user_id ORDER BY event_time DESC) AS dense_rank
FROM
  dsv1069.events

--
SELECT
  COALESCE(u.parent_user_id, u.id) AS user_id,
  u.email_address,
  i.id AS item_id,
  i.name AS item_name,
  i.category AS item_category
FROM
  (
    SELECT
      ve.user_id,
      ve.item_id,
      ve.event_time,
      row_number() OVER (PARTITION BY ve.user_id ORDER BY ve.event_time DESC) AS view_number
    FROM
      dsv1069.view_item_events ve
    WHERE
      ve.event_time > '2017-01-01'
  ) recent_views
JOIN dsv1069.users u ON u.id = recent_views.user_id
JOIN dsv1069.items i ON i.id = recent_views.item_id
LEFT OUTER JOIN dsv1069.orders o ON o.item_id = recent_views.item_id AND o.user_id = recent_views.user_id
WHERE view_number = 1
  AND u.deleted_at IS NOT NULL;

--
SELECT
    first_orders.user_id,
    DATE(first_orders.paid_at) AS first_order_date,
    DATE(second_orders.paid_at) AS second_order_date,
    DATE(second_orders.paid_at) - DATE(first_orders.paid_at) AS date_diff
FROM
    (
        SELECT
            user_id,
            invoice_id,
            paid_at,
            DENSE_RANK() OVER (PARTITION BY user_id ORDER BY paid_at ASC) AS order_num
        FROM
            dsv1069.orders
    ) AS first_orders
JOIN
    (
        SELECT
            user_id,
            invoice_id,
            paid_at,
            DENSE_RANK() OVER (PARTITION BY user_id ORDER BY paid_at ASC) AS order_num
        FROM
            dsv1069.orders
    ) AS second_orders
ON first_orders.user_id = second_orders.user_id
WHERE
    first_orders.order_num = 1
    AND second_orders.order_num = 2;

-- A B Test
SELECT
  -- COUNT(distinct e.parameter_value) as tests
  -- distinct e.parameter_value as tests
  e.parameter_value   as test_id,
  DATE(e.event_time)  as day,
  COUNT(*)            as event_rows
FROM
  dsv1069.events e
WHERE e.event_name = 'test_assignment'
AND parameter_name = 'test_id'
GROUP BY e.parameter_value, DATE(e.event_time)

--
SELECT
  test_id,
  user_id,
  COUNT(distinct test_assignment) as assignment
FROM
(
  SELECT 
    event_id, 
    event_time, 
    user_id, 
    platform,
    MAX(CASE 
      WHEN parameter_name = 'test_id' THEN CAST(parameter_value AS INT)
      ELSE NULL
    END) AS test_id,
    MAX(CASE 
      WHEN parameter_name = 'test_assignment' THEN parameter_value
      ELSE NULL
    END) AS test_assignment
  FROM 
    dsv1069.events 
  WHERE 
    event_name = 'test_assignment'
  GROUP BY 
    event_id, 
    event_time, 
    user_id, 
    platform
  ORDER BY 
    event_id
) test_events
-- WHERE
  -- test_id = 5
GROUP BY 
  test_id,
  user_id
ORDER BY 
  assignment DESC

-- A/B Testing
SELECT
  test_assignment,
  COUNT(user_id)    AS users,
  SUM(order_binary) AS users_with_orders
FROM
(
  SELECT
    assignments.user_id,
    assignments.test_id,
    assignments.test_assignment,
    -- MAX(CASE WHEN orders.created_at > assignments.event_time THEN orders.invoice_id ELSE NULL END ) order_after_assignment
    MAX(CASE WHEN orders.created_at > assignments.event_time THEN 1 ELSE 0 END ) order_binary
    -- COUNT(distinct (CASE WHEN orders.created_at > assignments.event_time THEN orders.invoice_id ELSE NULL END )) order_after_assignment,
    -- COUNT(distinct (CASE WHEN orders.created_at > assignments.event_time THEN orders.line_item_id ELSE NULL END )) items_after_assignment,
    -- SUM((CASE WHEN orders.created_at > assignments.event_time THEN orders.price ELSE 0 END)) AS totol_revenue
  FROM
  (
    SELECT 
      event_id, 
      event_time, 
      user_id,
      MAX(CASE 
        WHEN parameter_name = 'test_id' THEN CAST(parameter_value AS INT)
        ELSE NULL
      END) AS test_id,
      MAX(CASE 
        WHEN parameter_name = 'test_assignment' THEN parameter_value
        ELSE NULL
      END) AS test_assignment
    FROM 
      dsv1069.events 
    WHERE 
      event_name = 'test_assignment'
    GROUP BY 
      event_id, 
      event_time, 
      user_id
    ORDER BY 
      event_id
  ) assignments
  LEFT JOIN
    dsv1069.orders
  ON
    orders.user_id = assignments.user_id
  GROUP BY
    assignments.user_id,
    assignments.test_id,
    assignments.test_assignment
) user_level
WHERE
  test_id = 7
GROUP BY test_assignment


-- result
-- "test_assignment","users","users_with_orders"
-- "0",19376,2521
-- "1",19271,2633

-- What Could Go Wrong with the Analysis?
-- There could be errors or bias introduced in the assignment process
-- The metrics are not relevant to the hypothesis being tested
-- The metrics are not calculated properly - it happens
-- The statistics are not calculated properly

-- Aggregation of Mean Metrics
-- We will need more statistics
-- Average
-- Standard deviation
-- We need to figure out our P-values


--view
SELECT
  test_assignment,
  COUNT(user_id)    AS users,
  SUM(views_binary) AS users_with_views,
  SUM(views_binary_30d) AS views_binary_30d
FROM
(
  SELECT
    assignments.user_id,
    assignments.test_id,
    assignments.test_assignment,
    MAX(CASE WHEN views.event_time > assignments.event_time THEN 1 ELSE 0 END ) views_binary,
    MAX(CASE WHEN views.event_time > assignments.event_time AND
                  DATE_PART('day', views.event_time - assignments.event_time) <= 30
             THEN 1 ELSE 0 END) AS views_binary_30d
  FROM
  (
    SELECT 
      event_id, 
      event_time, 
      user_id,
      MAX(CASE 
        WHEN parameter_name = 'test_id' THEN CAST(parameter_value AS INT)
        ELSE NULL
      END) AS test_id,
      MAX(CASE 
        WHEN parameter_name = 'test_assignment' THEN parameter_value
        ELSE NULL
      END) AS test_assignment
    FROM 
      dsv1069.events 
    WHERE 
      event_name = 'test_assignment'
    GROUP BY 
      event_id, 
      event_time, 
      user_id
    ORDER BY 
      event_id
  ) assignments
  LEFT OUTER JOIN
    (
    SELECT *
    FROM
      dsv1069.events
    WHERE event_name = 'view_item'
    ) views
  ON
    views.user_id = assignments.user_id
  GROUP BY
    assignments.user_id,
    assignments.test_id,
    assignments.test_assignment
) user_level
WHERE
  test_id = 7
GROUP BY test_assignment

--
SELECT
  test_id,
  test_assignment,
  COUNT(user_id) AS user_id,
  AVG(invoices) AS avg_total_revenue,
  stddev(invoices) AS stddev_total_revenue
FROM
(
  SELECT
    assignments.user_id,
    assignments.test_id,
    assignments.test_assignment,
    COUNT(distinct 
      CASE WHEN orders.created_at > assignments.event_time 
      THEN orders.invoice_id ELSE NULL END ) invoices,
    COUNT(distinct 
      CASE WHEN orders.created_at > assignments.event_time 
      THEN orders.line_item_id ELSE NULL END ) line_items,
    COALESCE(SUM (
      CASE WHEN orders.created_at > assignments.event_time 
      THEN orders.price ELSE 0 END),0) total_revenue
  FROM
  (
    SELECT 
      event_id, 
      event_time, 
      user_id,
      MAX(CASE 
        WHEN parameter_name = 'test_id' THEN CAST(parameter_value AS INT)
        ELSE NULL
      END) AS test_id,
      MAX(CASE 
        WHEN parameter_name = 'test_assignment' THEN parameter_value
        ELSE NULL
      END) AS test_assignment
    FROM 
      dsv1069.events 
    WHERE 
      event_name = 'test_assignment'
    GROUP BY 
      event_id, 
      event_time, 
      user_id
    ORDER BY 
      event_id
  ) assignments
  LEFT OUTER JOIN 
    dsv1069.orders
  ON
    orders.user_id = assignments.user_id
  GROUP BY
    assignments.user_id,
    assignments.test_id,
    assignments.test_assignment
) user_level
-- WHERE
--   test_id = 7
GROUP BY test_id,test_assignment

-- result
-- "test_id","test_assignment","user_id","avg_total_revenue","stddev_total_revenue"
-- 4,"0",7210,0.16130374479889042996,0.40687048384305128388
-- 4,"1",4680,0.15619658119658119658,0.39844222719098433688
-- 5,"0",34420,0.15697269029633933759,0.39817403893114109521
-- 5,"1",34143,0.16058928623729607826,0.39977180473030909030
-- 6,"0",21687,0.15866648222437404897,0.40099414379769273443
-- 6,"1",21703,0.16122195088236649311,0.40665850048658558025
-- 7,"0",19376,0.14151527663088356730,0.38177616218377725474
-- 7,"1",19271,0.14872087592755954543,0.39005315257874438393
