
--Cancellation analysis


-- Cancellation rate by month
SELECT
    FORMAT_DATE('%b %Y', DATE_TRUNC(DATE(InvoiceDate), MONTH))  AS month,
    COUNT(DISTINCT InvoiceNo)                                    AS cancelled_orders,
    ROUND(SUM(ABS(Quantity) * ABS(Price)), 2)                   AS cancellation_value,
    ROUND(SUM(ABS(Quantity) * ABS(Price)) /
        SUM(SUM(ABS(Quantity) * ABS(Price))) OVER () * 100, 1)  AS pct_of_total_cancellations
FROM retail_year1.transactions_clean
WHERE InvoiceNo LIKE 'C%'
GROUP BY month, DATE_TRUNC(DATE(InvoiceDate), MONTH)
ORDER BY DATE_TRUNC(DATE(InvoiceDate), MONTH);


--Top 10 cancelled items 

select 
Description,
StockCode,
sum(ABS(Quantity) * ABS(Price)) as cancelled_revenue,
count(*) as cancelled_orders,
SUM(ABS(Quantity)) as cancelled_items
from retail_year1.transactions_clean 
where InvoiceNo LIKE 'C%'
group by Description,StockCode
order by cancelled_revenue desc limit 10;

select 
case when StockCode  IN ('M','D','POST','AMAZONFEE','BANK CHARGES','CRUK','TEST001','ADJUST') 
sum(ABS(Quantity) * ABS(Price)) as cancelled_revenue,
count(*) as cancelled_orders,
SUM(ABS(Quantity)) as cancelled_items
from retail_year1.transactions_clean 
where InvoiceNo LIKE 'C%'
group by Description,StockCode


-- Top 10 customers by cancellation value
SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo)                                    AS cancelled_orders,
    ROUND(SUM(ABS(Quantity) * ABS(Price)), 2)                   AS cancellation_value,
    COUNT(DISTINCT InvoiceNo) * 100.0 /
        SUM(COUNT(DISTINCT InvoiceNo)) OVER ()                  AS pct_of_all_cancellations
FROM retail_year1.transactions_clean 
WHERE InvoiceNo LIKE 'C%'
    AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY cancellation_value DESC
LIMIT 10;

-- what did the customer actually cancel ? Does it tally with top cancelled products ?

-- What did customer 16446 actually cancel?
SELECT
    InvoiceNo,
    CustomerID,
    StockCode,
    Description,
    ABS(Quantity)                           AS units_cancelled,
    ROUND(ABS(Price), 2)                    AS unit_price,
    ROUND(ABS(Quantity * Price), 2)         AS cancellation_value,
    DATE(InvoiceDate)                       AS cancel_date
FROM retail_year1.transactions_clean 
WHERE CustomerID = '16446'
    AND InvoiceNo LIKE 'C%'
ORDER BY cancellation_value DESC;

-- What did customer 12346 actually cancel?
SELECT
    InvoiceNo,
    CustomerID,
    StockCode,
    Description,
    ABS(Quantity)                           AS units_cancelled,
    ROUND(ABS(Price), 2)                    AS unit_price,
    ROUND(ABS(Quantity * Price), 2)         AS cancellation_value,
    DATE(InvoiceDate)                       AS cancel_date
FROM retail_year1.transactions_clean 
WHERE CustomerID = '12346'
    AND InvoiceNo LIKE 'C%'
ORDER BY cancellation_value DESC;


--Are these 2 customers completing large purchases

-- Purchase history vs cancellation history for both customers
SELECT
    CustomerID,
    CASE WHEN InvoiceNo LIKE 'C%' THEN 'Cancellation' ELSE 'Purchase' END   AS transaction_type,
    COUNT(DISTINCT InvoiceNo)                                                 AS order_count,
    SUM(ABS(Quantity))                                                        AS total_units,
    ROUND(SUM(ABS(Quantity) * ABS(Price)), 2)                                AS total_value
FROM retail_year1.transactions_clean 
WHERE CustomerID IN ('16446', '12346')
    AND StockCode NOT IN ('AMAZONFEE', 'BANK CHARGES' ,'M','TEST001','ADJUST','TEST002')
GROUP BY CustomerID, transaction_type
ORDER BY CustomerID, transaction_type;

select distinct stockcode,Description from retail_year1.transactions_clean 
WHERE CustomerID IN ('16446', '12346');

-- Identified there are transactions with invoices purchased and invoice cancelled.Chk if cancellation happening on same day ?
-- -- Flag any customers who bought the same product at the same price and qty more than once

SELECT
    CustomerID,
    StockCode,
    Quantity,
    Price,
    COUNT(*)  AS purchase_count
FROM retail_year1.transactions_clean 
WHERE InvoiceNo NOT LIKE 'C%'
    AND Quantity > 0
GROUP BY CustomerID, StockCode, Quantity, Price
HAVING COUNT(*) > 1
ORDER BY purchase_count DESC
LIMIT 10;















