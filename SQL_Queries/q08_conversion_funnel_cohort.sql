/* Query 08: Cohort map — Product View → Add to Cart → Purchase, Jan–Mar 2017*/

WITH product_events AS (
  SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    product.v2ProductName AS product_name,
    hits.eCommerceAction.action_type AS action_type,
    product.productRevenue AS revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE
    _TABLE_SUFFIX BETWEEN '0101' AND '0331'
)

,aggregated AS (
  SELECT
    month,
    COUNTIF(action_type = '2') AS num_product_view, 
    COUNTIF(action_type = '3')  AS num_addtocart,
    COUNTIF(action_type = '6' and revenue IS NOT NULL ) AS num_purchase
  FROM product_events
  GROUP BY month
)
SELECT
  month,
  num_product_view,
  num_addtocart,
  num_purchase,
  ROUND( (num_addtocart / num_product_view) * 100.0, 2) AS add_to_cart_rate,
  ROUND((num_purchase   / num_product_view) * 100.0, 2) AS purchase_rate
FROM aggregated
ORDER BY month;