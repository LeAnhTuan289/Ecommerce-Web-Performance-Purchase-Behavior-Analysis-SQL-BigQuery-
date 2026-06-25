/* Query 01: Calculate total visits, pageviews, transactions for Jan, Feb and March 2017 */

SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    sum(totals.visits) as visits,
    sum(totals.pageviews) as pageviews,
    sum(totals.transactions) as transactions
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _table_suffix between '0101' and '0331'
group by month
order by month;