use sample_db;
select * from superstore;
-- Exploratory data analysis
select count(*), count(distinct customer_id) ,count(distinct order_id), round(sum(profit)), min(order_date), max(order_date) from superstore;
-- Total profit, First order date and Latest order date for each category
select product_name,round(max(sales/quantity)), round(min(sales/quantity)) from superstore group by product_name;
-- Sub categories and products for each categories
select category, count(distinct sub_category), count(distinct product_id)
from superstore
group by category;
-- Sales, Profit and Quantites sold for each Categories and region
select category, region, sum(sales), sum(profit), sum(quantity)
from superstore
group by category,region;
-- Premium Customers, those who have done more orders than average no of orders per customer
with cte as 
(select customer_id, count(distinct order_id) as cnt 
	from superstore
	group by customer_id)
select * 
from cte
where cnt> (select avg(cnt) from cte); 
-- Product id and Total sales of Highest selling products (by no of units sold) in each category
   -- 1st Method
 with cte as (select category,product_id,count(sales) as cnt,floor(sum(sales) )as sm  from superstore
    group by category,product_id )
select c.category,c.product_id,c.cnt,d.highest,c.sm as total_sales from cte as c
join(select category,max(cnt) as highest from cte group by category) as d
on c.category=d.category
where c.cnt=d.highest;
  -- 2nd Method in terms of sales and not number of items sold
with cte as (select category,Product_ID, max(sales) as highest from superstore
group by category,Product_ID)
select s.product_id, s.sales
from cte as c
inner join superstore as s
on c.category=s.category 
and c.highest = s.sales;
-- Smallest and Largest city name (in case of two then sorted as per alphabetical order and limiting  one).
  -- 1st Method
select city ,concat(length(city)," ","Min_length") as max_min_city from superstore where length(city)=(select min(length(city)) from superstore ) 
union 
select city ,concat(length(city)," ", "Max_Length") as max_min_city from superstore where length(city)=(select max(length(city)) from superstore);
  -- 2nd Method
(select distinct city,length(city), "min" as len
from superstore
where length(city) = (select min(length(city)) from superstore)
order by city
limit 1)
union all
(select distinct city,length(city),"max" as len
from superstore
where length(city) = (select max(length(city)) from superstore)
order by city
limit 1);
-- all the orders in where some discount is provided to the customers
select * from superstore 
where discount!=0;
-- all the records in technology and furniture category for orders placed in the year 2020 
select * from superstore where category in ("Technology","Furniture") and year(order_date)="2020";
-- Sub categories and products for each categories?
select category, count(distinct sub_category), count(distinct product_id) from superstore group by category;
-- Sales, Profit and Quantites sold for each categories
select category, sum(sales), sum(profit), sum(quantity) from superstore group by category;
-- Total Sales for each region and ship mode combination for orders in year 2020
select region, ship_mode, sum(sales) from superstore where year(order_date)="2020" group by region, ship_mode;
-- quantities sold for combination of each category and subcategory
select category, sub_category, sum(quantity) from superstore group by category, sub_category;
-- Sub-Categories with High Average Profit(more than the half of the max profit in that sub-category)
SELECT sub_category, AVG(profit) AS AverageProfit, MAX(profit) AS MaxProfit
FROM sales_data
GROUP BY sub_category
HAVING AVG(profit) > 0.5 * MAX(profit);