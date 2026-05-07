-- Flagging highvalued products . assuming low values are given to known customers and high values for unknown or blank customer 

-- Anonymous high-value orders pattern
-- Products sold at 10x+ their average price, with no CustomerID
WITH product_avg AS (
    SELECT
        StockCode,
        ROUND(AVG(Price), 2)                            AS avg_price,
        ROUND(STDDEV(Price), 2)                         AS price_stddev
    FROM `retail_year1.transactions_clean`
    WHERE Price > 0
        AND Quantity > 0
        AND InvoiceNo NOT LIKE 'C%'
        AND CustomerID IS NOT NULL          -- use only known customers for baseline
        AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                              'BANK CHARGES','CRUK','TEST001','ADJUST')
    GROUP BY StockCode
    HAVING COUNT(DISTINCT CustomerID) >= 5  -- only products with enough baseline
)

SELECT
    t.InvoiceNo,
    t.StockCode,
    t.Description,
    t.Quantity,
    t.Price                                             AS charged_price,
    p.avg_price                                         AS normal_avg_price,
    ROUND(t.Price / NULLIF(p.avg_price, 0), 1)         AS price_multiple,
    ROUND(t.Quantity * t.Price, 2)                      AS order_value,
    t.CustomerID,
    DATE(t.InvoiceDate)                                 AS order_date,
    t.Country
FROM `retail_year1.transactions_clean` t
JOIN product_avg p ON t.StockCode = p.StockCode
WHERE t.Price > p.avg_price * 10           -- charged at 10x+ normal price
    AND t.CustomerID IS NULL               -- anonymous transactions only
    AND t.Quantity > 0
    AND t.InvoiceNo NOT LIKE 'C%'
ORDER BY price_multiple DESC
LIMIT 30;


-- Summary: total value of anomalous anonymous high-price orders
WITH product_avg AS (
    SELECT
        StockCode,
        ROUND(AVG(Price), 2)                            AS avg_price
    FROM `retail_year1.transactions_clean`
    WHERE Price > 0
        AND Quantity > 0
        AND InvoiceNo NOT LIKE 'C%'
        AND CustomerID IS NOT NULL
        AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                              'BANK CHARGES','CRUK','TEST001','ADJUST')
    GROUP BY StockCode
    HAVING COUNT(DISTINCT CustomerID) >= 5
)

SELECT
    COUNT(DISTINCT t.InvoiceNo)                         AS anomalous_invoices,
    COUNT(DISTINCT t.StockCode)                         AS products_affected,
    ROUND(SUM(t.Quantity * t.Price), 2)                 AS total_anomalous_value,
    ROUND(SUM(t.Quantity * p.avg_price), 2)             AS expected_value_at_normal_price,
    ROUND(SUM(t.Quantity * t.Price) 
        - SUM(t.Quantity * p.avg_price), 2)             AS overcharge_vs_normal
FROM `retail_year1.transactions_clean` t
JOIN product_avg p ON t.StockCode = p.StockCode
WHERE t.Price > p.avg_price * 10
    AND t.CustomerID IS NULL
    AND t.Quantity > 0
    AND t.InvoiceNo NOT LIKE 'C%';





  -- Isolate the truly extreme outliers -- 100x+ normal price
-- These are harder to explain as legitimate retail pricing
WITH product_avg AS (
    SELECT
        StockCode,
        ROUND(AVG(Price), 2)                            AS avg_price
    FROM `retail_year1.transactions_clean`
    WHERE Price > 0
        AND Quantity > 0
        AND InvoiceNo NOT LIKE 'C%'
        AND CustomerID IS NOT NULL
        AND StockCode NOT IN ('M','B','D','POST','AMAZONFEE',
                              'BANK CHARGES','CRUK','TEST001','ADJUST')
    GROUP BY StockCode
    HAVING COUNT(DISTINCT CustomerID) >= 5
)

SELECT
    t.InvoiceNo,
    t.StockCode,
    t.Description,
    t.Quantity,
    t.Price                                             AS charged_price,
    p.avg_price                                         AS wholesale_avg_price,
    ROUND(t.Price / NULLIF(p.avg_price, 0), 1)         AS price_multiple,
    ROUND(t.Quantity * t.Price, 2)                      AS order_value,
    DATE(t.InvoiceDate)                                 AS order_date
FROM `retail_year1.transactions_clean` t
JOIN product_avg p ON t.StockCode = p.StockCode
WHERE t.Price > p.avg_price * 100          -- 100x+ only -- harder to justify as retail
    AND t.CustomerID IS NULL
    AND t.Quantity > 0
    AND t.InvoiceNo NOT LIKE 'C%'
ORDER BY price_multiple DESC;  




