--qr1
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    sum(totals.visits) as visits,
    sum(totals.pageviews) as pageviews,
    sum(totals.transactions) as transactions
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _table_suffix between '0101' and '0331'
-- GROUP BY FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date))
group by month
order by month;


--qr2
SELECT
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.Bounces) as total_no_of_bounces,
    (sum(totals.Bounces)/sum(totals.visits))* 100.00 as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;


--qr3
with 
month_data as(
  SELECT
    "Month" as time_type,
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  order by revenue DESC
),

week_data as(
  SELECT
    "Week" as time_type,
    format_date("%Y%W", parse_date("%Y%m%d", date)) as week,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  order by revenue DESC
)

select * from month_data
union all
select * from week_data;
order by time_type



--qr4
with 
purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      (sum(totals.pageviews)/count(distinct fullvisitorid)) as avg_pageviews_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions>=1
  and product.productRevenue is not null
  group by month
),

non_purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      sum(totals.pageviews)/count(distinct fullvisitorid) as avg_pageviews_non_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
      ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions is null
  and product.productRevenue is null
  group by month
)

select
    pd.*,
    avg_pageviews_non_purchase
from purchaser_data pd
full join non_purchaser_data using(month)
order by pd.month;


--qr5
WITH
  transactions_per_user AS (
    SELECT
      FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
      fullVisitorId,
      SUM(totals.transactions) AS total_transactions
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
      UNNEST(hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE
      _table_suffix BETWEEN '0701' AND '0731'
      AND totals.transactions >= 1
      AND product.productRevenue IS NOT NULL
    GROUP BY
      fullVisitorId,month
  )

select
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    sum(totals.transactions)/count(distinct fullvisitorid) as Avg_total_transactions_per_user
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,unnest (hits) hits,
    unnest(product) product
where  totals.transactions>=1
and product.productRevenue is not null
group by month;


--qr6
SELECT
     FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    ROUND(((SUM(product.productRevenue) / 1000000) / sum(totals.visits)),2) AS avg_revenue_by_user_per_visit
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
WHERE
    _table_suffix BETWEEN '0701' AND '0731'
    AND totals.transactions IS NOT NULL
    AND product.productRevenue IS NOT NULL
group by month;


--qr7

with buyer_list as(
    SELECT
        distinct fullVisitorId  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
 AND totals.transactions>=1
GROUP BY other_purchased_products
ORDER BY quantity DESC;

-- qr8
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

