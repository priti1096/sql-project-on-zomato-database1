create database zomato;
use zomato;

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1, str_to_date('09-22-2017','%m-%d-%Y')),
(3,str_to_date('04-21-2017', '%m-%d-%Y'));

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,str_to_date('09-02-2014','%m-%d-%Y')),
(2,str_to_date('01-15-2015','%m-%d-%Y')),
(3,str_to_date('04-11-2014','%m-%d-%Y'));

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,str_to_date('04-19-2017','%m-%d-%Y'),2),
(3,str_to_date('12-18-2019','%m-%d-%Y'),1),
(2,str_to_date('07-20-2020','%m-%d-%Y'),3),
(1,str_to_date('10-23-2019','%m-%d-%Y'),2),
(1,str_to_date('03-19-2018','%m-%d-%Y'),3),
(3,str_to_date('12-20-2016','%m-%d-%Y'),2),
(1,str_to_date('11-09-2016','%m-%d-%Y'),1),
(1,str_to_date('05-20-2016','%m-%d-%Y'),3),
(2,str_to_date('09-24-2017','%m-%d-%Y'),1),
(1,str_to_date('03-11-2017','%m-%d-%Y'),2),
(1,str_to_date('03-11-2016','%m-%d-%Y'),1),
(3,str_to_date('11-10-2016','%m-%d-%Y'),1),
(3,str_to_date('12-07-2017','%m-%d-%Y'),2),
(3,str_to_date('12-15-2016','%m-%d-%Y'),2),
(2,str_to_date('11-08-2017','%m-%d-%Y'),2),
(2,str_to_date('09-10-2018','%m-%d-%Y'),3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

#1. What is total amount each customer spent on zomato ?
 select a.userid,a.product_id,sum(b.price) as total_amount 
 from sales as a inner join product as b on a.product_id = b.product_id
 group by userid;
 
 #2. How many days each customer visited zomato ?
 select userid, count(created_date) as total_days_visited from sales group by userid ;
 
 #3. What was the first product purchased by each customer ?
 select * from
 (select *,rank() over (partition by userid order by created_date) as rnk from sales)
 as a where rnk = 1  ;

#4. What is the most purchase product on menu and how many times it was purchased 
select userid, product_id, count(product_id) as Total_Purchased from sales where product_id = (select product_id
from sales group by product_id order by count(product_id) desc limit 1) group by userid;

#5. Which product was the most popular for each customer
select userid, product_id, cnt from (select *, rank() over 
(partition by userid order by cnt desc) as rnk from 
(select userid, product_id,count(product_id) as cnt 
from sales group by userid,product_id ) as a) as b where rnk =1 ;

#6. Which item was purchased first by the customer after they became a member ?
select* from
(select j.*, rank() over (partition by userid order by created_date) as rnk from
(select a.userid, a.created_date,a.product_id, b.gold_signup_date from sales as a inner join 
goldusers_signup as b on a.userid = b.userid
 and created_date >= gold_signup_date) as j) as k where rnk=1 ; 
 
 #7. What is total order and amount spent for each customer berfore they became a member
select userid, count(created_date) as total_orders,sum(price) as total_amt_spent from( select c.*, d.price from (select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a 
 inner join goldusers_signup as b on a.userid = b.userid and 
 created_date <=gold_signup_date) as c inner join product as d on c.product_id = d.product_id) as e group by userid;
 
/* 8. If buying each product generates points eg. for product1 = 5 points, product2 = 2 points,
 product3 =  5 points .Then
 1. calculate points collected by each customer 
 2. For which product most points have been collected */
 
 select userid,sum(total_zomato_points) from (select e.* , amt/Points as total_Zomato_points from 
 (select d.*,Case when product_id = 1 then 5 when product_id = 2 then 2 when product_id =3 then 5 
 else 0 end as Points from (select c.userid, c.product_id, sum(price) amt from 
 (select a.*, b.price from sales a inner join product b on a.product_id = b.product_id)
 as c group by userid,product_id) as d) as e) as f group by userid ;
 
 select * from
 (select *, rank() over (order by total_sum desc) as rnk
  from (select product_id,sum(total_zomato_points) as total_sum 
  from (select e.* , amt/Points as total_Zomato_points from 
  (select d.*,Case when product_id = 1 then 5 when product_id = 2 then 2 when product_id =3 then 5 
 else 0 end as Points from (select c.userid, c.product_id, sum(price) amt from 
 (select a.*, b.price from sales a inner join product b on a.product_id = b.product_id)
 as c group by userid,product_id) as d) as e) as f group by product_id ) as g) as h where rnk = 1;
 
/* 9. After getting gold membership how much points each customer earned during first year ?
 Consider 5 points for 10 rs. */
 
 select * , price/2 as Points from(select c.*,d.price from 
 (select a.*,b.gold_signup_date from sales a inner join goldusers_signup b on a.userid = b.userid
 where gold_signup_date <= created_date and created_date <= date_add(gold_signup_date, INTERVAL 365 DAY)) 
 as c inner join  product d on c.product_id = d.product_id ) as e ;
 
 #10. Rank all trasaction for each user 
 select *,rank() over ( partition by userid order by created_date)from sales;
 
 /* 11. Give rank to transaction which occurs after gold member membership for each user and mark NA 
 for transaction before gold membership */

select *, case when gold_signup_date is null then 'NA' else rnk end as final_rank from
 (select *,rank() over( partition by userid order by created_date desc) as rnk
 from (select a.userid, a.created_date, b.gold_signup_date from 
 sales a left outer join goldusers_signup b on a.userid = b.userid and created_date >=gold_signup_date ) 
 as c ) as d;
