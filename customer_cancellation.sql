
select 
case when CustomerID is null then 'no_customerid'
else 'customer_purchase' end as ind_customer,
ROUND(SUM(Quantity * Price), 2)        AS total_purchased_value,
count(*) as cnt_txn
from retail_year1.transactions_clean  group by ind_customer;


-- Cancellation rate by customer segment
-- What % of each customer's order value was cancelled?
WITH customer_purchases AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo)               AS total_orders,
        ROUND(SUM(Quantity * Price), 2)         AS total_purchased_value
    FROM retail_year1.transactions_clean 
    WHERE InvoiceNo NOT LIKE 'C%'
        AND Quantity > 0
        AND Price > 0
        AND CustomerID IS NOT NULL
        AND StockCode NOT IN ('M','D','POST','AMAZONFEE','BANK CHARGES','CRUK','TEST001','ADJUST')
    GROUP BY CustomerID
),

customer_cancellations AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo)               AS cancelled_orders,
        ROUND(SUM(ABS(Quantity * Price)), 2)    AS total_cancelled_value
    FROM retail_year1.transactions_clean 
    WHERE InvoiceNo LIKE 'C%'
        AND Price > 0
        AND CustomerID IS NOT NULL
        AND StockCode NOT IN ('M','D','POST','AMAZONFEE','BANK CHARGES','CRUK','TEST001','ADJUST')
    GROUP BY CustomerID
),

combined AS (
    SELECT
        p.CustomerID,
        p.total_purchased_value,
        COALESCE(c.total_cancelled_value, 0)    AS total_cancelled_value,
        ROUND(COALESCE(c.total_cancelled_value,0)
            / NULLIF(p.total_purchased_value,0) * 100, 1) AS cancellation_rate_pct
    FROM customer_purchases p
    LEFT JOIN customer_cancellations c USING (CustomerID)
)

select * from combined;

SELECT
    CASE
        WHEN cancellation_rate_pct = 0      THEN 'No cancellations'
        WHEN cancellation_rate_pct <= 10    THEN 'Low (<10%)'
        WHEN cancellation_rate_pct <= 50    THEN 'Medium (10–50%)'
        ELSE                                     'High (>50%)'
    END                                         AS cancellation_risk_segment,
    COUNT(*)                                    AS customer_count,
    ROUND(SUM(total_purchased_value), 2)        AS total_purchase_value,
    ROUND(SUM(total_cancelled_value), 2)        AS total_cancelled_value
FROM combined
GROUP BY cancellation_risk_segment
ORDER BY total_cancelled_value DESC;



select distinct customerId,
InvoiceNo
 from retail_year1.transactions_clean  where 
 customerID = '13091'
  AND StockCode NOT IN ('M','D','POST','AMAZONFEE','BANK CHARGES','CRUK','TEST001','ADJUST');


