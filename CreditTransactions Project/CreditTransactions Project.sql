use project;
select * from creditcard;
-- Top 5 cities with highest spends and their percentage contribution of total credit card spends
-- 1) Method..best
select city, round(100.0* sum(amount)/(select sum(amount) from creditcard),2) as top  from creditcard group by city order by top desc limit 5;
-- 2nd) Method ...using dense rank to avoid errors
with cte as (select city, sum(amount) as numerator
 from creditcard
 group by city)
select city,round(100*numerator/(select sum(numerator) from cte),2) as percent_contribution 
 from (select *,
 dense_rank() over (order by numerator desc) as rn from cte) as new 
 where rn between 1 and 5;
-- Highest spend month and amount spent in that month for each card type
-- 1st Method.. Highest spent month for each card
with cte as (
select card_type,year(transaction_date) as yr,monthname(transaction_date)as mn,
sum(amount) as total_per_month
from creditcard
group by card_type,year(transaction_date),monthname(transaction_date)
order by card_type,total_per_month desc)
select * from (select card_type,yr,mn as highest_month,total_per_month as highest_spend,
dense_rank() over (partition by card_type order by total_per_month desc) as rn
from cte) as new
where rn=1;
-- 2nd  way).. Highest spend in totality including all cards and the split of each card amount in that month
with cte as (
select card_type, year(transaction_date) as yr, monthname(transaction_date) as mn, sum(amount) as sums
from creditcard group by card_type, year(transaction_date) ,monthname(transaction_date) 
)
select yr,mn,card_type, sums, tot_month from 
 (select *, dense_rank() over (order by tot_month) as rn from 
(select *, sum(sums) over (partition by yr,mn  ) as tot_month from cte ) as a )
 as b where rn = 1;
-- Transaction details(all columns from the table) for each card type when it reaches cumulative of 1000000 total spends
with cte as 
(select *, sum(amount) over (partition by card_type order by  transaction_date,transaction_id) as cummulative from creditcard)
select card_type,cummulative from (select *, dense_rank() over (partition by card_type order by cummulative  ) as rn from cte
where cummulative>= 1000000) as a 
where rn =1;
-- 2nd method
with cte as (select *,
sum(amount) over (partition by card_type order by transaction_id,transaction_date) as tot
from creditcard)
select * 
from (select *,rank() over (partition by card_type order by tot) as rn
from cte 
where tot>=1000000) as tab
where rn=1;
-- City's spend from  gold card w.r.t total spend on gold card from all cities
-- 1st Method
select city, round(100*sum(amount)/(select sum(amount) from creditcard where card_type = "Gold" ),4) as  percntspend
from creditcard group by city,card_type order by  percntspend limit 1 ;
-- 2) Method
with cte as (select city,card_type, sum(amount) as numerator from creditcard group by city,card_type)
select *,100*numerator/(select sum(numerator) from cte) as percent_contribution 
from  (select *,
dense_rank() over (partition by card_type order by numerator) as rn from cte) as new 
where card_type= "Gold" and rn=1;
-- City's spend from  gold card w.r.t total spend on cards within the city
-- 1st Method
with cte as (select city,card_type, sum(amount) as numerator from creditcard group by city,card_type)
select *, 100* numerator/tot as percnt from (select c.*,d.tot from cte as c
join (select city,sum(numerator) as tot from cte group by city) as d
on c.city=d.city) as a where card_type ="Gold"
order by percnt limit 1;
 -- 2 Method..better
 with cte as (select city,card_type, sum(amount) as numerator
 from creditcard
 group by city,card_type
 having card_type="Gold")
select *,100*numerator/(select sum(numerator) from cte) as percent_contribution 
 from (select *,
 dense_rank() over (partition by card_type order by numerator) as rn from cte) as new 
 where rn=1;
 -- 3rd Method
 with cte as (select city,card_type, sum(amount) as numerator
 from creditcard
 group by city,card_type
 having card_type="Gold"
 order by numerator)
select *,100*numerator/(select sum(numerator) from cte) as percent_contribution 
from cte limit 1;
-- 4th Method
/*with cte as (
select city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from creditcard
group by city,card_type limit 1)
select 
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio;
select distinct exp_type from creditcard;*/
-- Query to print 3 columns:city, highest_expense_type,lowest_expense_type (example format : Delhi , bills, Fuel
-- 1st method
with cte as (select *,
max(amount) over (partition by city ) as rn1,
min(amount) over (partition by city ) as rn2
from creditcard)
select city,amount,
case when amount=rn1 then exp_type else "null" end as highest,
case when amount=rn2 then exp_type else "null" end as lowest
from cte
where amount in (rn1,rn2);
-- 2nd Method
select h.city,h.lowest,m.highest
from (with cte as (select *,
dense_rank() over (partition by city order by amount) as rn1
from creditcard)
select city,exp_type as lowest
from cte
where rn1=1) as h
inner join (with cte as (select *,
dense_rank() over (partition by city order by amount desc) as rn1
from creditcard)
select city,exp_type as highest
from cte
where rn1=1) as m
on h.city=m.city;
-- Percentage contribution of spends by females for each expense type
-- 1st method best
select exp_type, 
round(100.0*sum(case when gender= "F" then amount else 0 end)/sum(amount),1)as percent_contribute
from creditcard group by exp_type
order by percent_contribute desc;
-- 2nd Method
with cte as (
select gender,exp_type,sum(amount) as numer
from creditcard
where gender ="F"
group by gender,exp_type
)
select gender,exp_type,100.0*numer/(select sum(numer) from cte) as percent_contribution
from cte;
-- 3 Method
select g.*, h.tot,100*(g.contribution)/h.tot as perc_contr
from (select exp_type,gender, sum(amount) as contribution 
from creditcard
group by exp_type,gender
having gender= "F") as g
join(select exp_type,sum(amount) as tot
from creditcard
group by exp_type) as h
on g.exp_type=h.exp_type
-- Card and Expense type combination saw highest month over month growth in Jan-2014
-- 1st Method
with cte as (select monthname(transaction_date) as mnth, exp_type, card_type, sum(amount) as total
from creditcard where transaction_date between "2013-12-01" and "2014-01-31"
group by monthname(transaction_date),exp_type,card_type)
select mnth,exp_type,card_type,max(diff)
from (select *,
lag(total,1) over (partition by exp_type,card_type)-
total as diff from cte) as new
group by mnth,exp_type,card_type;
-- 2nd Method
select mnth,exp_type,card_type,max(diff)
from (select *,
(lag(total) over (partition by exp_type,card_type)-total as diff from cte) as lagged
group by mnth,exp_type,card_type
order by max(diff) desc
limit 1 ;
-- City with highest total spend to total no of transcations ratio during weekend
-- 1st Method
with cte as (select *, DAYOFWEEK (transaction_date) from creditcard where DAYOFWEEK (transaction_date) in(1,7))
select city, sum(amount)/count(transaction_id) as ratio from cte group by city order by ratio desc limit 1;
-- 2) Method
with cte as (select city,transaction_id,amount, DAYOFWEEK (transaction_date) 
from creditcard where DAYOFWEEK (transaction_date) in(1,7) 
order by transaction_date)
select city, sum(amount)/count(transaction_id) as ratio from cte group by cityorder by ratio desc limit 1;
-- City that took least number of days to reach its 500th transaction after the first transaction in that city
-- 1st Method
with cte as (select *,  count(transaction_date) over (partition by city order by transaction_date 
) as cnt, count(transaction_id) over (partition by city ) as dt from creditcard)
select * from cte where cnt>=500 and dt in (select min(dt) from cte);
-- 2nd Method
with cte as(select *,
row_number() over(partition by city order by transaction_date,transaction_id) as rn
from creditcard)
select city,timestampdiff(day,min(transaction_date),max(transaction_date)) as datediff1 from cte
where rn=1 or rn=500 group by city having count(1)=2 order by datediff1 limit 1; 