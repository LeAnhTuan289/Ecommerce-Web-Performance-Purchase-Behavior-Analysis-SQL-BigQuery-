/* Query 06: Average amount of money spent per session — purchasers only, July 2017 */

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