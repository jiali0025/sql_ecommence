SELECT * FROM order_details
SELECT * FROM order_list
SELECT * FROM sales_target 

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
        