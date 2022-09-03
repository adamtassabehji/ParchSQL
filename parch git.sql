

-- Top 10 customers by total spend

select round(avg(total_overall_amt),2)
from(
	select a.name, sum(total_amt_usd) total_overall_amt
	from orders o
	join accounts a
	on o.account_id = a.id
	group by a.name
	order by 2 desc
	limit 10) tbl1;
	

-- Identifying the top used channel for each customer

with tbl1 as(
	select a.name, w.channel, count(*) total
	from accounts a
	join web_events w
	on a.id = w.account_id
	group by a.name, w.channel
	order by name)

	select channel, count(name)
	from tbl1
	group by 1
	order by 2 desc
	

-- Identifying top sales rep in each region

with tbl1 as(
	select s.name sales_rep_name, r.name region_name, sum(o.total_amt_usd) total
	from region r
	join sales_reps s
	on s.region_id = r.id
	join accounts a
	on s.id = a.sales_rep_id
	join orders o
	on o.account_id = a.id
	group by s.name, r.name),
tbl2 as(
	select region_name, max(total) max_overall_total
	from tbl1
	group by region_name
)
select tbl1.region_name, tbl1.sales_rep_name, tbl2.max_overall_total
from tbl1
join tbl2
on tbl1.region_name = tbl2.region_name
and tbl1.total = tbl2.max_overall_total


-- Calculating the number of events in each channel for the top spending customer

with tbl1 as (
	select a.name, sum(total_amt_usd) total_spent
	from orders o
	join accounts a
	on o.account_id = a.id
	group by a.name
	order by total_spent desc
	limit 1)
select a.name, w.channel, count(*) num_events
from web_events w
join accounts a
on a.id = w.account_id and a.name = (select name from tbl1)
group by a.name, w.channel
order by num_events desc


-- Figuring out the domain type of customers' website

select right(website, 3) ext, count(*)
from accounts
group by ext;


-- Creating email addresses for customers based on rep name and company name

with t1 as (
select primary_poc, name,
    left(primary_poc, position(' ' in primary_poc)-1) first_name,
	right(primary_poc, length(primary_poc)- position(' ' in primary_poc)) lastname
from accounts
)
select primary_poc,
	concat(first_name, '.', lastname, '@',replace(name, ' ', ''), '.com')
from t1


-- Creating a new table to aggregate order figures at a customer level

select account_id, total_amt_usd,
	sum(total_amt_usd) over(partition by account_id) as overall_total_byaccount,
	count(*) over(partition by account_id) as count_byaccount
from orders


-- Create a running total of standard_amt_usd

select occurred_at, standard_amt_usd,accounts.long
	sum(standard_amt_usd) over(order by occurred_at) as running_total
from orders


-- Create a running total of standard_amt_usd by month

select occurred_at, standard_amt_usd, date_trunc('month', occurred_at),
	sum(standard_amt_usd) over(partition by date_trunc('month', occurred_at) order by occurred_at) as running_total_month
from orders


-- Ranking orders based on how much standard quantity a customer has purchased

select account_id, standard_qty,
	row_number() over(partition by account_id order by standard_qty),
	rank() over(partition by account_id order by standard_qty),
	dense_rank() over(partition by account_id order by standard_qty)
from orders


-- Adding summary stats to the query above 

select id, account_id, standard_qty,
	dense_rank() over(partition by account_id order by standard_qty) d_rank,
	sum(standard_qty) over (partition by account_id order by standard_qty) sum_std_qty,
	avg (standard_qty) over (partition by account_id order by standard_qty) avg_std_qty,
	min (standard_qty) over (partition by account_id order by standard_qty) min_std_qty,
	max (standard_qty) over (partition by account_id order by standard_qty) max_std_qty
from orders


-- Dividing the accounts into 4 levels in terms of the amount of standard_qty

select account_id, occurred_at, standard_qty,
	ntile(4) over(partition by account_id order by standard_qty) as standard_qty_quartile
from orders


