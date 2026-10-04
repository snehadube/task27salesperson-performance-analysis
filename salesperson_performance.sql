/* =====================================================================
   SALESPERSON PERFORMANCE ANALYSIS  |  Veda Technology - Data Analytics
   Dataset : Superstore (2014-2017)   |  Database : MySQL 8.x
   Note    : Superstore has no salesperson column. Salesperson = Regional
             Manager of the region (standard Superstore "People" table).
   ===================================================================== */

/* ---------- STEP 0 : DATABASE + TABLE ---------- */
CREATE DATABASE IF NOT EXISTS veda_sales;
USE veda_sales;

DROP TABLE IF EXISTS superstore;
CREATE TABLE superstore (
    row_id        INT,
    order_id      VARCHAR(20),
    order_date    DATE,
    ship_date     DATE,
    ship_mode     VARCHAR(20),
    customer_id   VARCHAR(15),
    customer_name VARCHAR(50),
    segment       VARCHAR(20),
    country       VARCHAR(30),
    city          VARCHAR(50),
    state         VARCHAR(30),
    postal_code   VARCHAR(10),
    region        VARCHAR(10),
    product_id    VARCHAR(20),
    category      VARCHAR(20),
    sub_category  VARCHAR(20),
    product_name  VARCHAR(200),
    sales         DECIMAL(12,4),
    quantity      INT,
    discount      DECIMAL(5,2),
    profit        DECIMAL(12,4),
    salesperson   VARCHAR(30),
    order_year    INT
);
/* Now import data/superstore_sql.csv with
   Workbench > right-click table 'superstore' > Table Data Import Wizard */

/* ---------- STEP 1 : DATA CHECKS ---------- */
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS orders,
       MIN(order_date) AS first_date, MAX(order_date) AS last_date
FROM superstore;                                   -- expect 9994 / 5009 / 2014-01-03 / 2017-12-30

SELECT SUM(salesperson IS NULL) AS null_salesperson,
       SUM(sales IS NULL OR profit IS NULL) AS null_values
FROM superstore;                                   -- expect 0 / 0

/* ---------- STEP 2 : CORE KPIs PER SALESPERSON ---------- */
SELECT salesperson, region,
       COUNT(DISTINCT state)                                  AS states,
       ROUND(SUM(sales),0)                                    AS total_sales,
       ROUND(SUM(profit),0)                                   AS total_profit,
       ROUND(SUM(profit)/SUM(sales)*100,1)                    AS profit_margin_pct,
       COUNT(DISTINCT order_id)                               AS orders,
       ROUND(SUM(sales)/COUNT(DISTINCT order_id),2)           AS avg_order_value,
       COUNT(DISTINCT customer_id)                            AS customers,
       ROUND(AVG(discount)*100,1)                             AS avg_discount_pct,
       ROUND(SUM(profit < 0)/COUNT(*)*100,1)                  AS loss_making_lines_pct
FROM superstore
GROUP BY salesperson, region
ORDER BY total_profit DESC;

/* ---------- STEP 3 : YEARLY SALES + YoY GROWTH ---------- */
WITH yearly AS (
    SELECT salesperson, order_year,
           SUM(sales)  AS sales,
           SUM(profit) AS profit
    FROM superstore
    GROUP BY salesperson, order_year
)
SELECT salesperson, order_year,
       ROUND(sales,0)  AS sales,
       ROUND(profit,0) AS profit,
       ROUND((sales - LAG(sales) OVER (PARTITION BY salesperson ORDER BY order_year))
             / LAG(sales) OVER (PARTITION BY salesperson ORDER BY order_year) * 100,1) AS yoy_growth_pct
FROM yearly
ORDER BY salesperson, order_year;

/* ---------- STEP 4 : CAGR 2014-2017 ---------- */
WITH y AS (
    SELECT salesperson,
           SUM(CASE WHEN order_year = 2014 THEN sales END) AS s2014,
           SUM(CASE WHEN order_year = 2017 THEN sales END) AS s2017
    FROM superstore
    GROUP BY salesperson
)
SELECT salesperson,
       ROUND(s2014,0) AS sales_2014, ROUND(s2017,0) AS sales_2017,
       ROUND((POW(s2017/s2014, 1.0/3) - 1) * 100, 1) AS cagr_pct
FROM y
ORDER BY cagr_pct DESC;

/* ---------- STEP 5 : TERRITORY VIEW (state level) ---------- */
SELECT salesperson, state,
       ROUND(SUM(sales),0)  AS sales,
       ROUND(SUM(profit),0) AS profit,
       ROUND(SUM(profit)/SUM(sales)*100,1) AS margin_pct,
       RANK() OVER (PARTITION BY salesperson ORDER BY SUM(profit) DESC) AS rank_in_territory
FROM superstore
GROUP BY salesperson, state
ORDER BY salesperson, rank_in_territory;

-- Loss-making states (the territory drag)
SELECT salesperson, state, ROUND(SUM(sales),0) AS sales, ROUND(SUM(profit),0) AS profit
FROM superstore
GROUP BY salesperson, state
HAVING SUM(profit) < 0
ORDER BY profit;

/* ---------- STEP 6 : DISCOUNT IMPACT ---------- */
SELECT salesperson,
       CASE WHEN discount = 0    THEN '1 No discount'
            WHEN discount <= 0.2 THEN '2 Up to 20%'
            WHEN discount <= 0.4 THEN '3 21-40%'
            ELSE                      '4 Above 40%' END AS discount_band,
       ROUND(SUM(sales),0)  AS sales,
       ROUND(SUM(profit),0) AS profit
FROM superstore
GROUP BY salesperson, discount_band
ORDER BY salesperson, discount_band;

/* ---------- STEP 7 : CATEGORY MIX ---------- */
SELECT salesperson, category,
       ROUND(SUM(sales),0)  AS sales,
       ROUND(SUM(profit),0) AS profit,
       ROUND(SUM(profit)/SUM(sales)*100,1) AS margin_pct
FROM superstore
GROUP BY salesperson, category
ORDER BY salesperson, profit DESC;

/* ---------- STEP 8 : FINAL RANKING (composite score, 0-100) ----------
   Model B = territory-fair (recommended)
   weights: sales/state 20%, profit/customer 20%, margin 20%, CAGR 20%, AOV 10%, discount discipline 10% */
WITH base AS (
    SELECT salesperson,
           SUM(sales)/COUNT(DISTINCT state)                    AS sales_per_state,
           SUM(profit)/COUNT(DISTINCT customer_id)             AS profit_per_customer,
           SUM(profit)/SUM(sales)                              AS margin,
           SUM(sales)/COUNT(DISTINCT order_id)                 AS aov,
           AVG(discount)                                       AS avg_discount,
           POW(SUM(CASE WHEN order_year=2017 THEN sales END)
             / SUM(CASE WHEN order_year=2014 THEN sales END), 1.0/3) - 1 AS cagr
    FROM superstore
    GROUP BY salesperson
),
scaled AS (
    SELECT salesperson,
      (sales_per_state     - MIN(sales_per_state)     OVER()) / (MAX(sales_per_state)     OVER() - MIN(sales_per_state)     OVER()) * 100 AS s_sps,
      (profit_per_customer - MIN(profit_per_customer) OVER()) / (MAX(profit_per_customer) OVER() - MIN(profit_per_customer) OVER()) * 100 AS s_ppc,
      (margin              - MIN(margin)              OVER()) / (MAX(margin)              OVER() - MIN(margin)              OVER()) * 100 AS s_margin,
      (cagr                - MIN(cagr)                OVER()) / (MAX(cagr)                OVER() - MIN(cagr)                OVER()) * 100 AS s_cagr,
      (aov                 - MIN(aov)                 OVER()) / (MAX(aov)                 OVER() - MIN(aov)                 OVER()) * 100 AS s_aov,
      100 - (avg_discount  - MIN(avg_discount)        OVER()) / (MAX(avg_discount)        OVER() - MIN(avg_discount)        OVER()) * 100 AS s_disc
    FROM base
)
SELECT salesperson,
       ROUND(0.20*s_sps + 0.20*s_ppc + 0.20*s_margin + 0.20*s_cagr + 0.10*s_aov + 0.10*s_disc, 1) AS composite_score,
       RANK() OVER (ORDER BY 0.20*s_sps + 0.20*s_ppc + 0.20*s_margin + 0.20*s_cagr + 0.10*s_aov + 0.10*s_disc DESC) AS final_rank
FROM scaled
ORDER BY final_rank;
