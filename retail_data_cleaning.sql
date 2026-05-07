CREATE OR REPLACE TABLE `retail-margin-analysis.retail_year1.retail_data` AS
SELECT * FROM `retail-margin-analysis.retail_year1.year1`
UNION ALL 
SELECT * FROM `retail-margin-analysis.retail_year1.year2`;


-- convert the data type 

CREATE OR REPLACE TABLE `retail_year1.transactions_clean` AS
SELECT 
  InvoiceNo,
  StockCode,
  Description,
  CAST(Quantity AS INT64) AS Quantity,
  PARSE_DATETIME('%m/%d/%y %H:%M', InvoiceDate) AS InvoiceDate,
  CAST(UnitPrice AS FLOAT64) AS Price,
  CustomerID,
  Country
FROM `retail-margin-analysis.retail_year1.retail_data`;

select * from  `retail_year1.online_retail_clean` limit 5;

--MoM sales

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(DATE(InvoiceDate), MONTH)                        AS sales_month,
        COUNT(DISTINCT InvoiceNo)                                    AS total_orders,
        SUM(Quantity)                                                AS total_units_sold,
        ROUND(SUM(Quantity * Price), 2)                             AS total_revenue,
        COUNT(DISTINCT CustomerID)                                   AS unique_customers,
        ROUND(SUM(Quantity * Price) /
              COUNT(DISTINCT InvoiceNo), 2)                         AS avg_order_value
    FROM `retail_year1.transactions_clean`
    WHERE
        Quantity > 0
        AND Price > 0
        AND CustomerID IS NOT NULL
        AND StockCode != 'B'                        -- exclude bad debt
        AND InvoiceNo NOT LIKE 'C%'                 -- exclude cancellations
        AND InvoiceNo NOT LIKE 'A%'                 -- exclude adjustments (A506401 etc)
    GROUP BY sales_month
),

mom_comparison AS (
    SELECT
        sales_month,
        total_orders,
        total_units_sold,
        total_revenue,
        unique_customers,
        avg_order_value,

        ROUND(
            (total_revenue - LAG(total_revenue) OVER (ORDER BY sales_month))
            / NULLIF(LAG(total_revenue) OVER (ORDER BY sales_month), 0) * 100
        , 1)                                                        AS revenue_mom_pct,

        ROUND(
            (total_units_sold - LAG(total_units_sold) OVER (ORDER BY sales_month))
            / NULLIF(LAG(total_units_sold) OVER (ORDER BY sales_month), 0) * 100
        , 1)                                                        AS units_mom_pct,

        ROUND(
            (total_orders - LAG(total_orders) OVER (ORDER BY sales_month))
            / NULLIF(LAG(total_orders) OVER (ORDER BY sales_month), 0) * 100
        , 1)                                                        AS orders_mom_pct

    FROM monthly_sales
)

SELECT * FROM mom_comparison
ORDER BY sales_month;

--  exclusion summary

        SELECT
    COUNTIF(InvoiceNo LIKE 'C%')                                    AS cancelled_invoices,
    COUNTIF(StockCode = 'B')                                        AS bad_debt_entries,
    COUNTIF(InvoiceNo LIKE 'A%')                                    AS adjustment_entries,
    ROUND(SUM(CASE WHEN StockCode = 'B' 
              THEN Quantity * Price ELSE 0 END), 2)                 AS bad_debt_value,
    ROUND(SUM(CASE WHEN InvoiceNo LIKE 'C%' 
              THEN ABS(Quantity * Price) ELSE 0 END), 2)            AS cancellation_value
FROM `retail_year1.transactions_clean`;







