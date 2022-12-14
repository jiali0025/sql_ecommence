---- Query 1: Show the number and percentage for each customer segment as the final result. Order the results by the percentage of customers
-- combine the order_detail table with order_list table
CREATE VIEW combined_orders AS
SELECT d.Order_ID, d.Amount, d.Profit, d.Quantity, d.Sub_Category, l.Order_Date, l.CustomerName, l.State, l.City
FROM order_details AS d 
INNER JOIN order_list AS l 
ON d.Order_ID = l.Order_ID 

-- segment the customers into group based on RFM model 
CREATE VIEW customer_grouping AS
SELECT *,
    CASE 
        WHEN (R>=4 AND R<=5) AND (((F+M)/2)>= 4 AND ((F+M)/2)<= 5) THEN 'Champions'
        WHEN (R>=2 AND R<=5) AND (((F+M)/2)>= 3 AND ((F+M)/2)<= 5) THEN 'Loyal Customers'
        WHEN (R>=3 AND R<=5) AND (((F+M)/2)>= 1 AND ((F+M)/2)<= 3) THEN 'Potential Loyalist'
        WHEN (R>=4 AND R<=5) AND (((F+M)/2)>= 0 AND ((F+M)/2)<= 1) THEN 'New Customers'
        WHEN (R>=3 AND R<=4) AND (((F+M)/2)>= 0 AND ((F+M)/2)<= 1) THEN 'Promising'
        WHEN (R>=2 AND R<=3) AND (((F+M)/2)>= 2 AND ((F+M)/2)<= 3) THEN 'Customers Needing Attention'
        WHEN (R>=2 AND R<=2) AND (((F+M)/2)>= 0 AND ((F+M)/2)<= 2) THEN 'About to Sleep'
        WHEN (R>=0 AND R<=2) AND (((F+M)/2)>= 2 AND ((F+M)/2)<= 5) THEN 'At Risk'
        WHEN (R>=0 AND R<=1) AND (((F+M)/2)>= 4 AND ((F+M)/2)<= 3) THEN "Can't Lost Them"
        WHEN (R>=1 AND R<=2) AND (((F+M)/2)>= 1 AND ((F+M)/2)<= 2) THEN 'Hibernating'
        WHEN (R>=0 AND R<=2) AND (((F+M)/2)>= 0 AND ((F+M)/2)<= 2) THEN 'Lost'
            END AS customer_segment
FROM (
    SELECT
    MAX(STR_TO_DATE(order_date, '%d-%m-%Y') AS lastest_order_date,
    CustomerName,
    DATEDIFF(STR_TO_DATE('31-03-2019', '%d-%m-%Y'), MAX(STR_TO_DATE(order_date, '%d-%m-%Y'))) AS recency,
    COUNT(DISTINCT order_id) AS frequency,
    SUM(Amount) AS monetary,
    NTILE(5) OVER (ORDER BY  DATEDIFF(STR_TO_DATE('31-03-2019', '%d-%m-%Y'), MAX(STR_TO_DATE(order_date, '%d-%m-%Y')))DESC) AS R,
    NTILE(5) OVER (ORDER BY COUNT(DISTINCT order_id) ASC) AS F,
    NTILE(5) OVER (ORDER BY SUM(Amount) ASC) AS M
    FROM combined_orders
    GROUP BY CustomerName)rfm_table
GROUP BY CustomerName;
        
-- return the number & percentage of each customer segment
SELECT
    customer_segment,
    COUNT(DISTINCT CustomerName) AS num_of_cusomters,
    ROUND(COUNT(DISTINCT CustomerName) / (SELECT COUNT(*) FROM customer_grouping) *100, 2) AS pct_of_cusomters
FROM customer_grouping
GROUP BY customer_segment
ORDER BY pct_of_cusomters DESC;

---- Query 2: Find the number of orders, customers, cities, and states
-- number of orders, customers, cities, states
SELECT COUNT(DISTINCT order_id) AS num_of_orders,
       COUNT(DISTINCT CustomerName) AS num_of_customers,
       COUNT(DISTINCT City) AS num_of_cities,
       COUNT(DISTINCT State) AS num_of_states
FROM combined_orders;

---- Query 3: Find the new customers who made purchases in the year 2019. Only shows the top 5 new customers and their respective cities and states. Order the result by the amount the year.
-- top 5 new customers
SELECT CustomerName, State, City, SUM(Amount) AS sales
FROM combined_orders
WHERE CustomerName NOT IN (
    SELECT DISTINCT CustomerName
    FROM combined_orders
    WHERE YEAR(STR_TO_DATE(order_date, '%d-%m-%Y')) =2018)
AND YEAR(STR_TO_DATE(order_date, '%d-%m-%Y')) =2019
GROUP BY CustomerName
ORDER BY sales DESC
LIMIT 5;

---- Query 4: Find the top 10 profitable states & cities so that the company can expand its business
-- number of customers, quantities sold and profit made & quantity sold in state & city
SELECT
    State,
    City, 
    COUNT(DISTINCT CustomerName) AS num_of_customers,
    SUM(Profit) AS total_profit,
    SUM(Quantity) AS total_quantity
FROM combined_orders
GROUP BY State, City
ORDER BY total_profit DESC 
LIMIT 10???

---- Query 5: Display the deatils for the first order in each state. Order the result by "order_id"
-- first order in each state
SELECT order_date, order_id, State, City, CustomerName
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY State, order_id) AS RoWNumberPerState
FROM combined_orders)firstorder
WHERE RowNumberPerState = 1
ORDER BY order_id;

---- Query 6: Determine the number of orders (in the form of a histogram) and sales for different days of the week
-- sales in different days
SELECT 
    day_of_order,
    LPAD('*', num_of_orders, '*') AS num_of_orders,
    sales
FROM 
    (SELECT
        DAYNAME(STR_TO_DATE(order_date, '%d%m%Y')) AS day_of_order,
        COUNT(DISTINCT order_id) AS num_of_orders,
        SUM(Quantity) AS quantity,
        SUM(Amount) AS sales
    FROM combined_orders
    GROUP BY day_of_order) sales_per_day
ORDER BY sales DESC;

---- Query 7: Check the monthly profitability and monthly quantity sold to see if there are patterns in the dataset
SELECT CONCAT(MONTHNAME(STR_TO_DATE(order_date, '%d%m%Y')), "-", YEAR(STR_TO_DATE(order_date, '%d%m%Y')) AS month_of_year,
       SUM(Profit) AS total_profit, SUM(Quantity) AS total_quantity
FROM combined_orders
GROUP BY month_of_year
ORDER BY month_of_year = 'April-2018' DESC,
         month_of_year = 'May-2018' DESC,
         month_of_year = 'June-2018' DESC,
         month_of_year = 'July-2018' DESC,
         month_of_year = 'August-2018' DESC,
         month_of_year = 'September-2018' DESC,
         month_of_year = 'October-2018' DESC,
         month_of_year = 'November-2018' DESC,
         month_of_year = 'December-2018' DESC,
         month_of_year = 'January-2019' DESC,
         month_of_year = 'February-2019' DESC,
         month_of_year = 'March-2019' DESC;

---- Query 8: Determine the number of times that salespeople hit or failed to hit the sales target for each category
-- find out the sales for each category in each month 
CREATE VIEW sales_by-category AS
SELECT CONCAT(SUBSTR(MONTHNAME(STR_TO_DATE(order_date, '%d%m%Y')), 1, 3), "-", SURSTR(YEAR(STR_TO_DATE(order_date, '%d%m%Y')), 3, 2)) AS order_monthyear, Category, SUM(Amount) AS Sales
FROM combined_orders
GROUP BY order_monthyear, Category;

-- check if the sales hit the target set for each category in each month
CREATE VIEW sales_vs_target AS
SELECT *, CASE 
            WHEN Sales >= Target THEN 'Hit'
            ELSE 'Fail'
        END AS hit_or_fail
FROM 
    (SELECT s.order_monthyear, sCategory, s.Sales, t.Target
    FROM sales_by_category AS s
    INNER JOIN sales_target AS t ON s.order_monthyear = t.month_of_order
    AND s.Category = t.Category) st;

-- return the number of times that the target is met & the number of times that the target is not met
SELECT h.Category, h.Hit, f.Fail
FROM 
    (SELECT Category, COUNT(*) AS Hit
    FROM sales_vs_target
    WHERE hit_or_fail LIKE 'Hit'
    GROUP BY Category) h 
INNER JOIN 
    (SELECT Category, COUNT(*) AS Fail
    FROM sales_vs_target
    WHERE hit_or_fail LIKE 'Fail'
    GROUP BY Category) f 
ON h.Category = f.Category;

---- Query 9: Find the total sales, total profit, and total quantity sold for each category and sub-category. Return the maximum cost and maximum price for each sub-category too
-- find order quantity, profit, amount for each subcategory
-- eletronic games & tables subcategoryies resulted in loss
CREATE VIEW order_detials_by_total AS
SELECT Category, sub_category,
       SUM(Quantity) AS total_order_quantity,
       SUM(Profit) AS total_profit,
       SUM(Amount) AS total_amount
FROM order_details
GROUP BY sub_category
ORDER BY total_order_quantity DESC;

-- Maximum cost per unit & maximum price per unit for each subcategory
CREATE VIEW order_details_by_unit AS
SELECT Category, sub_category, MAX(cost_per_unit) AS max_cost, MAX(price_per_unit) AS max_price
FROM (SELECT *, round((Amount-Profit)/Quantity, 2) AS cost_per_unit, round(Amount/Quantity, 2) AS price_per_unit
      FROM order_details) c 
GROUP BY sub_category
ORDER BY max_cost DESC;

-- combine order_details_by_unit and order_details_by_total table
SELECT t.Category, t.sub_category, t.total_order_quantity, t.total_profit, t.total_amount, u.max_cost, u.max_price
FROM order_details_by_total AS t 
INNER JOIN order_details_by_unit AS u 
ON t.sub_category = u.sub_category; 


