-- Inspecting data
SELECT * FROM retail
LIMIT 5;

-- Basic information 
-- How many customers? -- 5,878
SELECT COUNT(DISTINCT `Customer ID`) FROM retail;
-- How many products? -- 5,283
SELECT COUNT(DISTINCT Description) FROM retail; 
-- How many orders? -- 779,425
SELECT COUNT(Invoice) FROM retail; 
-- What is the date range? -- From 2009/12 to 2011/12 
SELECT MAX(InvoiceDate),MIN(InvoiceDate) FROM retail; 

-- In this step we will understand data from three aspects: timeseries, products and countries
-- 1. Which month is best for sales in a specific year? How much was earned that month?
SELECT MONTH(InvoiceDate) AS Month_ID, ROUND(SUM(Sales),2) AS Revenue, COUNT(Invoice) AS Frequency
FROM retail
WHERE YEAR(InvoiceDate) = 2010 -- change year to see the rest
GROUP BY Month_ID
ORDER BY Revenue DESC;

-- 2. Seems November is the best month in each year, what product do they sell in November?
SELECT MONTH(InvoiceDate) AS Month_ID, Description, COUNT('Quantity') AS Quantity, ROUND(SUM(Sales)) AS Revenue
FROM retail
GROUP BY 1,2
HAVING MOnth_ID = 11 -- change month to see the rest
ORDER BY Revenue DESC, Quantity DESC
LIMIT 10;

-- 3. Which country has the most revenue and orders?
SELECT country, COUNT(Invoice) AS Orders, ROUND(SUM(sales)) AS Revenue
FROM retail
GROUP BY country
ORDER BY Revenue DESC, Orders DESC;


-- RFM
CREATE TABLE rfm (
    `Customer ID` INT,
    Monetary_value DECIMAL(10, 2),
    Avg_monetary_value DECIMAL(10, 2),
    Frequency_value INT,
    Last_order_date DATE,
    Max_order_date DATE,
    Recency_value INT,
    Recency_score INT,
    Frequency_score INT,
    Monetary_score INT,
    rfm_cells INT,
    rfm_score VARCHAR(10)
);
INSERT INTO rfm 
WITH rfm_value AS
(
	SELECT 
		`Customer ID`, 
		ROUND(SUM(Sales)) AS Monetary_value,
		ROUND(AVG(Sales)) AS Avg_monetary_value,
		COUNT(Invoice) AS Frequency_value,
		MAX(InvoiceDate) AS Last_order_date,
		(SELECT MAX(InvoiceDate) FROM retail) AS Max_order_date,
		DATEDIFF((SELECT MAX(InvoiceDate) FROM retail), MAX(InvoiceDate)) AS Recency_value
	FROM retail
	GROUP BY `Customer ID`
),
score AS
(
	SELECT 
		*,
		NTILE(4) OVER(ORDER BY Recency_value DESC) AS Recency_score,
		NTILE(4) OVER(ORDER BY Frequency_value) AS Frequency_score,
		NTILE(4) OVER(ORDER BY Avg_monetary_value) AS Monetary_score
	FROM rfm_value
) 
SELECT 
	*,
	Recency_score+Frequency_score+Monetary_score AS rfm_cells,
	CONCAT(CAST(Recency_score AS CHAR), CAST(Frequency_score AS CHAR), CAST(Monetary_score AS CHAR)) AS rfm_score
FROM score;

-- User segmentation
WITH segmentation AS
(
	SELECT 
		`Customer ID`,Recency_score, Frequency_score, Monetary_score, rfm_score,
		CASE 
			WHEN rfm_score IN ('111','112','211','212','121','122','221','222') THEN 'heberating'
			WHEN rfm_score IN ('113','114','213','214','123','124','223','224') THEN 'about to sleep'
			WHEN rfm_score IN ('311','312','321','322','411','412','421','422') THEN 'new customers'
			WHEN rfm_score IN ('313','314','323','324','413','414','423','424') THEN 'need attention'
			WHEN rfm_score IN ('131','132','141','142','231','232','241','242') THEN 'at risk'
			WHEN rfm_score IN ('133','134','143','144','233','234','243','244') THEN 'cannot lose'
			WHEN rfm_score IN ('331','332','341','342','431','432','441','442') THEN 'loyal customers'
			WHEN rfm_score IN ('333','334','343','344','433','434','443','444') THEN 'champoins'
		END AS segment
	FROM rfm
)
SELECT segment, COUNT(*) AS customer_number
FROM segmentation
GROUP BY segment;


-- Basket analysis
-- Which two products are most sold together? 
WITH t1 AS
(
	SELECT
		r1.Invoice, 
        r1.`Customer ID`, 
        r1.Description AS product_1, 
        r2.Description AS product_2
	FROM retail r1 
	JOIN retail r2 ON r1.Invoice = r2.Invoice
	WHERE r1.Description > r2.Description
)
SELECT product_1, product_2, COUNT(*) bought_together
FROM t1
GROUP BY product_1, product_2
ORDER BY bought_together DESC
LIMIT 10;

-- Which Three products are most sold together?
WITH t2 AS
(
	SELECT
		r1.Invoice, 
        r1.`Customer ID`, 
        r1.Description AS product_1, 
        r2.Description AS product_2,
        r3.Description AS product_3
	FROM retail r1  
	JOIN retail r2 ON r1.Invoice = r2.Invoice
    JOIN retail r3 ON r1.Invoice = r3.Invoice
	WHERE r1.Description > r2.Description AND r2.Description > r3.Description
)
SELECT product_1, product_2, product_3, COUNT(*) AS bought_together
FROM t2
GROUP BY product_1, product_2, product_3
ORDER BY bought_together DESC
LIMIT 10;