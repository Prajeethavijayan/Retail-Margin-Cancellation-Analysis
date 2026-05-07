-- Price variance by product
WITH product_pricing AS (
    SELECT
        StockCode,
        Description,
        COUNT(DISTINCT InvoiceNo)                       AS total_orders,
        COUNT(DISTINCT Price)                           AS distinct_prices,
        ROUND(MIN(Price), 2)                            AS min_price,
        ROUND(MAX(Price), 2)                            AS max_price,
        ROUND(AVG(Price), 2)                            AS avg_price,
        ROUND(STDDEV(Price), 2)                         AS price_stddev,
        ROUND((MAX(Price) - MIN(Price)) 
            / NULLIF(MIN(Price), 0) * 100, 1)           AS price_variance_pct
    FROM `retail_year1.transactions_clean`
    WHERE Quantity > 0
        AND Price > 0
        AND InvoiceNo NOT LIKE 'C%'
        AND InvoiceNo NOT LIKE 'A%'
        AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                              'BANK CHARGES','CRUK','TEST001','ADJUST')
    GROUP BY StockCode, Description
    HAVING COUNT(DISTINCT Price) > 1        -- only products with multiple prices
        AND COUNT(DISTINCT InvoiceNo) >= 10 -- ignore rarely sold products
        AND MIN(Price) > 0
)

SELECT
    StockCode,
    Description,
    total_orders,
    distinct_prices,
    min_price,
    max_price,
    avg_price,
    price_stddev,
    price_variance_pct
FROM product_pricing
ORDER BY price_variance_pct DESC
LIMIT 20;

-- there are some invoices for large items , but priced at 0 . why?


    SELECT
    StockCode,
        DATE_TRUNC(DATE(InvoiceDate), MONTH)                        AS sales_month,
        COUNT(DISTINCT InvoiceNo)                                    AS total_orders,
        SUM(Quantity)                                                AS total_units_sold,
        ROUND(SUM(Quantity * Price), 2)                             AS total_revenue,
        COUNT(DISTINCT CustomerID)                                   AS unique_customers
    FROM `retail_year1.transactions_clean`
    WHERE
        Quantity > 0
        AND Price =0
        AND InvoiceNo NOT LIKE 'C%'
        AND InvoiceNo NOT LIKE 'A%'
        AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                              'BANK CHARGES','CRUK','TEST001','ADJUST')
    GROUP BY StockCode,sales_month



-- Which product appears more frequently at zero price?
With  avg_price as
(
select 
stockcode,
AVG(Price)  as normal_avg_price
 FROM `retail_year1.transactions_clean` p
  where InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                          'BANK CHARGES','CRUK','TEST001','ADJUST')
                           AND Price > 0
            AND Quantity > 0
group by stockcode
),

zero_q as (
    SELECT
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo)                           AS times_ordered_free,
    SUM(Quantity)                                       AS total_free_units,
    COUNT(DISTINCT CustomerID)                          AS unique_customers,
FROM `retail_year1.transactions_clean` t
WHERE Price = 0
    AND Quantity > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                          'BANK CHARGES','CRUK','TEST001','ADJUST')
    --and DATE_TRUNC(DATE(InvoiceDate), MONTH) = DATE '2010-08-01'
GROUP BY StockCode, Description
)

    select 
    a.* ,
    b.normal_avg_price
    from 
    zero_q a
    left join 
    avg_price b  on a.StockCode = b.StockCode
    order by total_free_units desc
    ;

--Checking for Aug'10

-- Specifically isolate Aug 2010 zero-price orders
-- to confirm this explains the anomaly
SELECT
    InvoiceNo,
    CustomerID,
    StockCode,
    Description,
    Quantity,
    Price,
    DATE(InvoiceDate)                                   AS order_date
FROM `retail_year1.transactions_clean`
WHERE DATE_TRUNC(DATE(InvoiceDate), MONTH) = DATE '2010-08-01'
    AND Price = 0
    AND Quantity > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                          'BANK CHARGES','CRUK','TEST001','ADJUST')
ORDER BY Quantity DESC
LIMIT 20;


84016

    SELECT
    StockCode,
        DATE_TRUNC(DATE(InvoiceDate), MONTH)                        AS sales_month,
        COUNT(DISTINCT InvoiceNo)                                    AS total_orders,
        SUM(Quantity)                                                AS total_units_sold,
        ROUND(SUM(Quantity * Price), 2)                             AS total_revenue,
        COUNT(DISTINCT CustomerID)                                   AS unique_customers
    FROM `retail_year1.transactions_clean`
    WHERE
        Quantity > 0
        AND Price >0
        AND InvoiceNo NOT LIKE 'C%'
        AND InvoiceNo NOT LIKE 'A%'
        AND StockCode  IN ('84016')
            
    GROUP BY StockCode,sales_month;

    select 
stockcode,
AVG(Price)  as normal_avg_price
 FROM `retail_year1.transactions_clean` p
  where InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                          'BANK CHARGES','CRUK','TEST001','ADJUST')
                           AND Price > 0
            AND Quantity > 0
            and stockcode  IN ('84016')
group by stockcode


select * from retail_year1.transactions_clean where stockcode  IN ('84016')
and price > 0


-- Overall summary — total implied revenue lost to zero-price orders
SELECT
    COUNT(DISTINCT t.InvoiceNo)                         AS zero_price_invoices,
    COUNT(DISTINCT t.StockCode)                         AS distinct_products,
    SUM(t.Quantity)                                     AS total_free_units,
    ROUND(SUM(t.Quantity * p.avg_price), 2)             AS total_implied_revenue_lost
FROM `retail_year1.transactions_clean` t
JOIN (
    SELECT StockCode, AVG(Price) AS avg_price
    FROM `retail_year1.transactions_clean`
    WHERE Price > 0 AND Quantity > 0
        AND InvoiceNo NOT LIKE 'C%'
    GROUP BY StockCode
) p ON t.StockCode = p.StockCode
WHERE t.Price = 0
    AND t.Quantity > 0
    AND t.InvoiceNo NOT LIKE 'C%'
    AND t.InvoiceNo NOT LIKE 'A%'
    AND t.StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                            'BANK CHARGES','CRUK','TEST001','ADJUST');


