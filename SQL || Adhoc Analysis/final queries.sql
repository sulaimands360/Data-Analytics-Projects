
-- Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select * from dim_customer;

select  distinct market
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';



-- What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields

select count(distinct product_code) as unique_products_2021 from fact_sales_monthly
where fiscal_year = 2021;

select count(distinct product_code) as unique_products_2020 from fact_sales_monthly
where fiscal_year = 2020;


with cte1 as 
(
select count(distinct product_code) as unique_products_2021 from fact_sales_monthly
where fiscal_year = 2021
),
cte2 as
(
select count(distinct product_code) as unique_products_2020 from fact_sales_monthly
where fiscal_year = 2020
),
cte3 as (
select unique_products_2021, unique_products_2020
from cte1
cross join cte2)

select *, round(((unique_products_2021 - unique_products_2020)/unique_products_2020)*100, 1) as PCT_CHNG
 from cte3;


-- (334 - 245)/ 245 = 0.3633 == 36.33%


-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts.

select segment,
		count(product_code) as product_count
        from dim_product
        group by segment
        order by product_count desc;
        
        
 -- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020?       

select count(distinct product_code) as unique_products_2021 from fact_sales_monthly
where fiscal_year = 2021;

select count(distinct product_code) as unique_products_2020 from fact_sales_monthly
where fiscal_year = 2020;

select 
	p.segment,
    count(distinct case when S.fiscal_year = 2020 then S.product_code end) as product_count_2020,
	count(distinct case when S.fiscal_year = 2021 then S.product_code end) as product_count_2021,
    
    (count(distinct case when S.fiscal_year = 2021 then S.product_code end)-
    count(distinct case when S.fiscal_year = 2020 then S.product_code end)) as difference

from dim_product as p
left join fact_sales_monthly as S on p.product_code = S.product_code
where S.fiscal_year in (2020, 2021)
group by p.segment
order by difference desc;

    
-- Get the products that have the highest and lowest manufacturing costs.


select p.product_code, p.product,
		f.manufacturing_cost
from dim_product as p
left join fact_manufacturing_cost as f on p.product_code = f.product_code
where manufacturing_cost = (select max(manufacturing_cost) 
								from fact_manufacturing_cost)
UNION
select p.product_code, p.product,
		f.manufacturing_cost
from dim_product as p
left join fact_manufacturing_cost as f on p.product_code = f.product_code
where manufacturing_cost = (select min(manufacturing_cost) 
								from fact_manufacturing_cost);


        
-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. 

with cte1 as (

		select a.customer_code,
        a.customer, a.market, b.fiscal_year, b.pre_invoice_discount_pct
        from dim_customer as a
        join fact_pre_invoice_deductions as b
        on a.customer_code = b.customer_code

),
cte2 as 
(
			select customer_code,
            customer,
            market,
            fiscal_year,
            avg(pre_invoice_discount_pct) as average_discount_pct
            from cte1
            where fiscal_year = 2021 and market = 'India'
            group by customer_code, customer, market, fiscal_year
)

select customer_code, customer, round(average_discount_pct*100, 2) as average_discount_pct
 from cte2
 order by average_discount_pct desc
 limit 5;



-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.

-- Gross sales = Price * sold_quantity

with cte1 as 
(

			select a.customer_code,
            a.customer,
			b.date,
            b.product_code,
            b.fiscal_year,
            b.sold_quantity
            from dim_customer as a
            join fact_sales_monthly as b
            on a.customer_code = b.customer_code
            where a.customer = 'Atliq Exclusive'
),
cte2 as (
		select a.customer_code,
			   a.customer,
               a.date,
               a.product_code,
               a.fiscal_year,
               a.sold_quantity,
               b.gross_price from cte1 as a
        join fact_gross_price as b
        on a.product_code = b.product_code
        )
        
	select monthname(date) as Month,
			fiscal_year as Year,
            round(sum(sold_quantity*gross_price)/1000000, 2) as gross_sales_amt,
            'Millions' as Unit
            from cte2
            group by monthname(date), fiscal_year;



-- In which quarter of 2020, got the maximum total_sold_quantity?

-- Business year is starting from the Month September
-- Hence my year will start from september
-- hence, september to november will be my 1st quarter
-- , Dec to Feb will be my 2nd quarter
-- , Mar to May will be my 3rd quarter
-- , Jun to Aug will be my 4th quarter

select * from fact_sales_monthly
where fiscal_year in (2020, 2021);

select case
			when date between '2019-09-01' and '2019-11-01' then 1
            when date between '2019-12-01' and '2020-02-01' then 2
            when date between '2020-03-01' and '2020-05-01' then 3
            when date between '2020-06-01' and '2020-08-01' then 4
            end    as Quarters,
            
            format(sum(sold_quantity), 0) as total_sold_quantity
            from fact_sales_monthly
            where fiscal_year = 2020
            group by Quarters
            order by total_sold_quantity desc;
            

-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution?


-- pct contribution = (gross sales mln / total sales)*100



with cte1 as 
(
			select a.channel,
            b.product_code,
            b.fiscal_year,
            b.sold_quantity
            from dim_customer as a
            join fact_sales_monthly as b
            on a.customer_code = b.customer_code
            where fiscal_year = 2021
),

cte2 as (
		select a.channel, a.product_code, a.sold_quantity, b.gross_price
        from cte1 as a
        join fact_gross_price as b
        on a.product_code = b.product_code
        ),
        
        cte3 as (
        select channel,
			round(sum(sold_quantity*gross_price)/1000000, 2) as gross_sales_mln
            from cte2
            group by channel)
            
            
	select channel, gross_sales_mln,
			round((gross_sales_mln/total_sales)*100, 2) as pct_contrib
     from cte3,
		(select sum(gross_sales_mln) as total_sales from cte3) as total
        order by gross_sales_mln desc;
        
        
-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021?


with cte1 as 

(
			select a.division,
            a.product_code,
            a.product,
            sum(b.sold_quantity) as total_sold_quantity
            from dim_product as a
            join fact_sales_monthly as b
            on a.product_code = b.product_code
            where b.fiscal_year = 2021
            group by a.division, a.product_code, a.product
),

-- I need to show 3 top products per division, top products will be based on total
-- sold quantity

cte2 as (
	select *, rank() over (partition by division order by total_sold_quantity desc) as rnk
    from cte1

)

select * from cte2
where rnk <= 3;





