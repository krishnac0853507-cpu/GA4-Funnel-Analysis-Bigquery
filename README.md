GA4 E-Commerce Funnel Analysis
Tools: BigQuery (SQL) · Google Public Dataset
Focus: Conversion rate diagnosis and funnel drop-off analysis
Business Problem
The store's conversion rate was below industry average. This analysis identifies exactly where users are dropping off in the purchase funnel and provides data-driven recommendations to fix it.
Key Findings
77% drop-off at Visit → Product View — users are not engaging with products from the homepage
54.5% drop-off at Checkout → Purchase — the biggest revenue leak in the funnel
71% of users who reached checkout never completed the purchase
Tablet users convert best; mobile dominates top-of-funnel traffic
November cohort had the highest conversion rate; performance has declined since
Business Recommendations
Redesign homepage for better product discovery
Simplify to single-page checkout and add trust signals
Optimize mobile checkout experience
Investigate what drove November's strong conversions and replicate it
SQL Concepts Used
CTEs · Window Functions · JOINs · UNNEST · Aggregate Functions · Subqueries
Files
ga4_funnel_queries.sql — All 8 SQL queries
01_event_types.csv to 07_cohort.csv — Query result exports
