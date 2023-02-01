/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region. */

SELECT DISTINCT market
FROM dim_customer
WHERE customer='Atliq Exclusive' AND region='APAC' ;

/* 2. What is the percentage of unique product increase in 2021 vs. 2020?
 The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg */

with 
temp1 as
(SELECT COUNT(DISTINCT(product_code)) AS Unique_products_2020
FROM fact_sales_monthly
WHERE fiscal_year=2020), 
temp2 as 
(SELECT COUNT(DISTINCT(product_code)) AS Unique_products_2021
FROM fact_sales_monthly
WHERE fiscal_year=2021) 
SELECT a.Unique_Products_2020, b.Unique_Products_2021, 
		ROUND(100*(b.unique_products_2021-a.unique_products_2020)/a.unique_products_2020,2) as Percentage_Change
from temp1 as a
join temp2 as b;


/*3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
The final output contains 2 fields, segment, product_count */

SELECT  segment, COUNT(DISTINCT product) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY COUNT(DISTINCT product) DESC;

/* 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
 The final output contains these fields, segment, product_count_2020, product_count_2021, difference */

WITH 
temp_t1 AS
(SELECT 
p.Segment, 
COUNT( DISTINCT CASE WHEN ms.fiscal_year = 2020 THEN p.product_code END) AS Unique_Count_2020,
COUNT( DISTINCT CASE WHEN ms.fiscal_year = 2021 THEN p.product_code END) AS Unique_Count_2021
FROM dim_product as p
JOIN fact_sales_monthly as ms
ON p.product_code=ms.product_code
group by Segment)
SELECT *, (unique_count_2021-unique_count_2020) as Difference
FROM temp_t1
ORDER BY Difference DESC;

/* 5. Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, product_code, product, manufacturing_cost */

(SELECT mc.product_code, p.product, MAX(mc.manufacturing_cost) as manufacturing_cost
FROM  fact_manufacturing_cost mc
JOIN dim_product p
ON mc.product_code=p.product_code
GROUP BY mc.product_code, p.product
ORDER BY manufacturing_cost DESC
LIMIT 1)
UNION ALL
(SELECT mc.product_code, p.product, MIN(mc.manufacturing_cost) as manufacturing_cost
FROM  fact_manufacturing_cost mc
JOIN dim_product p
ON mc.product_code=p.product_code
GROUP BY mc.product_code, p.product
ORDER BY manufacturing_cost ASC
LIMIT 1);

/* 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
 The final output contains these fields, customer_code ,customer ,average_discount_percentage */

SELECT pid.customer_code, c.customer, ROUND(AVG(pid.pre_invoice_discount_pct),2) as discount_percentage
FROM fact_pre_invoice_deductions pid
JOIN dim_customer c
ON pid.customer_code= c.customer_code
WHERE pid.fiscal_year=2021 AND market='India'
GROUP BY pid.customer_code, c.customer
ORDER BY discount_percentage DESC
LIMIT 5;


/* 7. The Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions.*/

SELECT MONTHNAME(ms.date) AS Month, YEAR(ms.date) AS Year,ROUND(SUM(ms.sold_quantity*gpt.gross_price),2) AS Gross_Sales
FROM fact_sales_monthly AS ms
JOIN fact_gross_price AS gpt
ON gpt.product_code=ms.product_code

JOIN dim_customer AS c
ON ms.customer_code=c.customer_code

WHERE c.customer='Atliq Exclusive'
GROUP BY Month, Year
ORDER BY Year ASC;

/* 8. In which quarter of 2020, got the maximum total_sold_quantity?
 The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity*/

SELECT 
  CASE 
    WHEN MONTH(ms.date) IN (9,10,11) THEN 1
    WHEN MONTH(ms.date) IN (12,1,2) THEN 2
    WHEN MONTH(ms.date) IN (3,4,5) THEN 3
    WHEN MONTH(ms.date) IN (6,7,8) THEN 4
  END AS Quarter,
  SUM(sold_quantity) AS Total_Sold_Quantity
FROM fact_sales_monthly as ms
WHERE fiscal_year=2020
GROUP BY Quarter
ORDER BY Total_Sold_Quantity desc;

/* 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields, channel ,gross_sales_mln, percentage */

SELECT c.channel, ROUND((SUM(ms.sold_quantity*gpt.gross_price)/1000000),2) AS Gross_sales_mln, ROUND ((SUM(ms.sold_quantity*gpt.gross_price)*100)/sum(SUM(ms.sold_quantity*gpt.gross_price)) over(),2) as Percentage
FROM fact_sales_monthly AS ms
JOIN fact_gross_price AS gpt
ON gpt.product_code=ms.product_code

JOIN dim_customer AS c
ON ms.customer_code=c.customer_code
WHERE ms.fiscal_year=2021
GROUP BY c.channel
ORDER BY Percentage DESC; 



 /* 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
 The final output contains these fields division, product_code ,product, total_sold_quantity, rank_order */

WITH 
temp_t1 AS
(SELECT p.division,
	p.product_code,
    p.Product,
    sum(ms.sold_quantity) AS Total_Quantity_Sold
FROM dim_product AS p
JOIN fact_sales_monthly as ms
ON p.product_code = ms.product_code
WHERE ms.fiscal_year=2021
GROUP BY division, product_code ,product),
temp_t2 AS
(SELECT *, RANK() OVER(PARTITION BY division ORDER BY Total_Quantity_Sold DESC) AS Rank_Order
from temp_t1)
SELECT *
FROM temp_t2
WHERE Rank_Order<=3; 
 
 
 
 
 