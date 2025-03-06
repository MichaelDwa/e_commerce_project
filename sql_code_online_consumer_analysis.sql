-- Project 1: E-Commerce Online Consumer Analysis

CREATE TABLE online_consumer_behavior (
    row_id INT NOT NULL,
    order_id INT NOT NULL,
    order_date DATE NULL,
    order_priority VARCHAR(20) NULL,
    order_quantity INT NULL,
    sales NUMERIC(10, 2),
    discount NUMERIC(10, 2),
    ship_mode VARCHAR(20) NULL,
    profit NUMERIC(10, 2),
    unit_price NUMERIC(10, 2),
    shipping_costs NUMERIC(10, 2),
    customer_name VARCHAR(50) NULL,
    province VARCHAR(50) NULL,
    region VARCHAR(50) NULL,
    customer_segment VARCHAR(50) NULL,
    product_category VARCHAR(50) NULL,
    product_subcategory VARCHAR(50) NULL,
    product_name VARCHAR(100) NULL,
    product_container VARCHAR(50) NULL,
    product_base_margin NUMERIC(10, 2),
    ship_date DATE NULL,
    dataset VARCHAR(20) NULL
);

-- 1. Product and Profit Analysis

-- 1A. Which products have the highest and lowest profit margins, by product?

-- For the highest profit margin

SELECT  
    product_name,                       
    product_base_margin,                
    SUM(sales) AS total_sales,       
    SUM(profit) AS total_profit      
FROM 
    online_consumer_behavior
GROUP BY 
    product_name, product_base_margin  
HAVING 
    SUM(profit) > 0  
ORDER BY 
    SUM(profit) DESC  
LIMIT 10;

-- For the lowest profit margin

SELECT  
    product_name,                      
    product_base_margin,                
    SUM(sales) AS total_sales,       
    SUM(profit) AS total_profit      
FROM 
    online_consumer_behavior
GROUP BY 
    product_name, product_base_margin  
ORDER BY 
    CASE
        WHEN product_base_margin IS NULL THEN 1  
        ELSE 0  
    END,
    product_base_margin ASC  
LIMIT 10;  

-- 1B. How does the profit margin compare across different product categories and subcategories? 

SELECT 
    product_category,
    product_subcategory,
    AVG(product_base_margin) AS avg_margin,
    SUM(sales) AS total_sales
FROM 
    online_consumer_behavior
GROUP BY 
    product_category, product_subcategory
ORDER BY 
    avg_margin DESC;

-- 2. Geographic Data Insights

-- 2A. Which regions have the highest sales revenue and profit margins? 

SELECT 
    region,                         
    SUM(sales) AS total_sales,      
    SUM(profit) AS total_profit     
FROM 
    online_consumer_behavior
GROUP BY 
    region                         
ORDER BY 
    total_sales DESC, total_profit DESC;  

-- 2B. What products are more popular in these regions? 

WITH ranked_products AS (
    SELECT 
        region,                        
        product_name,                 
        SUM(sales) AS total_sales,    
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sales) DESC) AS rank  
    FROM 
        online_consumer_behavior       
    GROUP BY 
        region, product_name            
)

SELECT 
    region,                        
    product_name,                  
    total_sales                   
FROM 
    ranked_products                
WHERE 
    rank = 1                        
ORDER BY 
    total_sales DESC;              

-- 2C. Which regions have high or low shipping costs compared to sales and profit, and how can we improve shipping costs in these areas? 

SELECT 
    region,
    SUM(shipping_costs) AS total_shipping_costs,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    (SUM(shipping_costs) / NULLIF(SUM(sales), 0)) AS shipping_cost_to_sales_ratio,
    (SUM(shipping_costs) / NULLIF(SUM(profit), 0)) AS shipping_cost_to_profit_ratio
FROM 
    online_consumer_behavior
GROUP BY 
    region
ORDER BY 
    shipping_cost_to_sales_ratio DESC;

-- 3. Customer Purchasing Patterns and Trends

-- 3A. What are the top-selling products in each product subcategory? 

WITH ranked_products AS (
    SELECT
        product_category,
        product_subcategory,
        product_name,
        SUM(sales) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY product_category, product_subcategory ORDER BY SUM(sales) DESC) AS rank
    FROM 
        online_consumer_behavior
    GROUP BY 
        product_category,
        product_subcategory,
        product_name
)
SELECT
    product_category,
    product_subcategory,
    product_name,
    total_sales
FROM
    ranked_products
WHERE
    rank = 1
ORDER BY 
    product_category,
    product_subcategory;
    
-- 3B. How do purchasing patterns vary across different customer segments? 

SELECT 
    customer_segment,
    AVG(product_base_margin) AS avg_margin,
    AVG(order_quantity) AS avg_order_quantity,
    SUM(sales) AS total_sales
FROM 
    online_consumer_behavior
GROUP BY 
    customer_segment
ORDER BY 
    avg_margin DESC;
    
-- 3C. What is the top-selling product in each customer segment, and what is the average product margin for those top-selling products? 

WITH ranked_products AS (
    SELECT 
        customer_segment,
        product_name,
        SUM(sales) AS total_sales,
        AVG(product_base_margin) AS avg_product_margin,
        ROW_NUMBER() OVER (PARTITION BY customer_segment ORDER BY SUM(sales) DESC) AS rank
    FROM 
        online_consumer_behavior
    GROUP BY 
        customer_segment, product_name
)
SELECT 
    customer_segment,
    product_name,
    total_sales,
    avg_product_margin
FROM 
    ranked_products
WHERE 
    rank = 1  
ORDER BY 
    customer_segment;
    
-- 3D. How do product base margins correlate with sales volume and profit for specific customer segments? 

SELECT 
    customer_segment,
    AVG(product_base_margin) AS avg_product_margin,
    SUM(order_quantity) AS total_order_volume,
    SUM(profit) AS total_profit,
    SUM(sales) AS total_sales
FROM 
    online_consumer_behavior
GROUP BY 
    customer_segment
ORDER BY 
    avg_product_margin DESC;

-- 4. Order and Profitability Insights

-- 4A. What is the average profit per order, and how does it vary by product category, region, or customer segment? 

SELECT 
    product_category,
    region,
    customer_segment,
    AVG(profit) AS avg_profit_per_order
FROM 
    online_consumer_behavior
GROUP BY 
    product_category, region, customer_segment
ORDER BY 
    avg_profit_per_order DESC;

-- 4B. How do shipping costs impact overall profitability for each order or customer segment? 

SELECT 
    customer_segment,
    SUM(shipping_costs) AS total_shipping_costs,
    SUM(profit) AS total_profit,
    AVG(shipping_costs) AS avg_shipping_costs_per_order,
    (SUM(shipping_costs) / NULLIF(SUM(profit), 0)) AS shipping_cost_to_profit_ratio
FROM 
    online_consumer_behavior
GROUP BY 
    customer_segment
ORDER BY 
    shipping_cost_to_profit_ratio DESC;

-- 4C. How do different customer segments behave in terms of purchasing frequency, order volume, and profitability? 

SELECT 
    customer_segment,
    COUNT(DISTINCT order_id) AS order_frequency,  
    SUM(order_quantity) AS total_order_volume,    
    SUM(profit) AS total_profit,
    AVG(profit) AS avg_profit_per_order
FROM 
    online_consumer_behavior
GROUP BY 
    customer_segment
ORDER BY 
    total_profit DESC, total_order_volume DESC;

-- 5. Customer Lifetime Value (CLV) and Retention

-- 5A. Can we identify customer segments with the highest lifetime value based on their purchasing behavior? 

SELECT 
    customer_segment,
    COUNT(DISTINCT customer_name) AS num_customers,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    AVG(sales) AS avg_sales_per_customer,
    AVG(profit) AS avg_profit_per_customer
FROM 
    online_consumer_behavior
GROUP BY 
    customer_segment
ORDER BY 
    total_sales DESC, total_profit DESC;
    
-- 5B. What factors (such as product category, discount usage, or order frequency) are most closely linked to high customer retention?

SELECT 
    customer_segment,
    product_category,
    AVG(order_quantity) AS avg_order_quantity,
    AVG(discount) AS avg_discount,
    COUNT(DISTINCT order_id) AS order_frequency,
    COUNT(DISTINCT customer_name) AS retained_customers
FROM 
    online_consumer_behavior
GROUP BY 
    customer_segment, product_category
ORDER BY 
    order_frequency DESC, retained_customers DESC;

-- 6. Marketing and Sales Strategy

-- 6A. Which customer segments or regions should be targeted with special promotions to increase profitability? 

SELECT 
    customer_segment,
    region,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM 
    online_consumer_behavior
GROUP BY 
    customer_segment, region
ORDER BY 
    total_profit DESC, total_sales DESC;

-- 6B. Which types of products or shipping methods should be promoted to maximize overall profit margins? 

SELECT 
    product_category,
    ship_mode,
    AVG(product_base_margin) AS avg_margin,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM 
    online_consumer_behavior
GROUP BY 
    product_category, ship_mode
ORDER BY 
    avg_margin DESC, total_sales DESC;

-- 7. Shipping and Delivery Insights

-- 7A. How does delivery time (from ship date to order date) differ by shipping method and order priority, and what are the total sales for each combination? 

SELECT  
    ship_mode,
    order_priority,
    AVG(ship_date - order_date) AS avg_delivery_time_days,  
    SUM(sales) AS total_sales
FROM 
    online_consumer_behavior
GROUP BY 
    ship_mode, order_priority  
ORDER BY 
    avg_delivery_time_days DESC, total_sales DESC;  

-- 7B. What are the average shipping delays in different regions, and what factors might affect these delays? 

SELECT 
    region,
    AVG(ship_date - order_date) AS avg_delivery_delay_days, 
    COUNT(*) AS total_orders,
    AVG(order_quantity) AS avg_order_quantity,
    COUNT(DISTINCT order_priority) AS unique_order_priorities,
    COUNT(DISTINCT ship_mode) AS unique_shipping_modes
FROM 
    online_consumer_behavior
WHERE 
    ship_date > order_date  
GROUP BY 
    region
ORDER BY 
    avg_delivery_delay_days DESC;

-- 8. Data Quality and Completeness

-- 8A. How much missing data is there for order dates, product information, or shipping costs, and how does this impact reporting? 

SELECT 
    COUNT(*) AS total_rows,
    COUNT(order_date) AS completed_order_date,
    COUNT(product_name) AS completed_product_name,
    COUNT(shipping_costs) AS completed_shipping_costs,
    COUNT(product_category) AS completed_product_category,
    COUNT(product_subcategory) AS completed_product_subcategory,
    (COUNT(*) - COUNT(order_date)) AS missing_order_date,
    (COUNT(*) - COUNT(product_name)) AS missing_product_name,
    (COUNT(*) - COUNT(shipping_costs)) AS missing_shipping_costs,
    (COUNT(*) - COUNT(product_category)) AS missing_product_category,
    (COUNT(*) - COUNT(product_subcategory)) AS missing_product_subcategory
FROM 
    online_consumer_behavior;

-- 8B. Are there any regions with missing or inconsistent data, such as missing order priorities or shipping modes, and how can these issues be addressed?

SELECT 
    region,
    COUNT(*) AS total_orders,
    COUNT(order_priority) AS completed_order_priority,
    COUNT(ship_mode) AS completed_ship_mode,
    (COUNT(*) - COUNT(order_priority)) AS missing_order_priority,
    (COUNT(*) - COUNT(ship_mode)) AS missing_ship_mode
FROM 
    online_consumer_behavior
GROUP BY 
    region
ORDER BY 
    missing_order_priority DESC, missing_ship_mode DESC;

-- 9. Shipping Mode and Profitability

-- 9A. How does the shipping mode influence profit margins for different products or categories? 

SELECT 
    product_category,
    ship_mode,
    AVG(product_base_margin) AS avg_margin,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM 
    online_consumer_behavior
GROUP BY 
    product_category, ship_mode
ORDER BY 
    avg_margin DESC;
