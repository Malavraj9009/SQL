Data Analysis Questions

--1) How many customers has Foodie-Fi ever had?

select count(distinct(customer_id) from foodie_fi.subscriptions

--2) What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

select Count(plan_id) as Number of people,DATE_TRUNC('month',start_date) as months from foodie_fi.subscriptions
where plan_id=0
GROUP BY months

--3) What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select p.plan_name,p.plan_id,count(*) as events from foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
ON p.plan_id = s.plan_id
Where s.start_date>'2020-12-31'
group by p.plan_id,p.plan_name

--4) What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

select plan_id, count(customer_id) as no_of_customer,
round(100 *count(DISTINCT customer_id) / 
       count(DISTINCT customer_id),1) as distinct customers
from foodie_fi.subscriptions
where plan_id=4
group by plan_id

--5) How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

WITH churning AS 
(
SELECT 
  s.customer_id, 
  s.plan_id, 
  p.plan_name,
  ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.plan_id) AS plan_rank
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id
)
  
SELECT 
  COUNT(*) AS churn_count,
  ROUND(100 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),0) AS churn_percentage
FROM churning
WHERE plan_id = 4
  AND plan_rank = 2

--6) What is the number and percentage of customer plans after their initial free trial?

WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions)

SELECT 
  next_plan, 
  COUNT(*) AS conversions,
  ROUND(100 * COUNT(*)::NUMERIC / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS conversion_percentage
FROM next_plan_cte
WHERE next_plan IS NOT NULL 
  AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan

--7) What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) as next_date
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31'
),
customer_breakdown AS (
SELECT plan_id, COUNT(DISTINCT customer_id) AS customers
  FROM next_plan_cte
  WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31'))
    OR (next_date IS NULL AND start_date < '2020-12-31')
  GROUP BY plan_id)

SELECT plan_id, customers, 
  ROUND(100 * customers::NUMERIC / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id

--8) How many customers have upgraded to an annual plan in 2020?

select count(distinct customer_id) as cus
from foodie_fi.subscriptions 
where plan_id=3
and start_date <= '2020-12-31'

--9) How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH 
  trial_plan_date AS 
  (SELECT 
      customer_id, 
      start_date AS trial_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0
  ),
  annual_plan_date AS
  (SELECT 
      customer_id, 
      start_date AS annual_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3
  )

SELECT 
  ROUND(AVG(annual_date - trial_date),0) AS avg_days_to_upgrade
FROM trial_plan_date tp
JOIN annual_plan_date ap
  ON tp.customer_id = ap.customer_id

--10) How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(plan_id, 1) OVER(
    PARTITION BY customer_id 
    ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions)

SELECT 
  COUNT(*) AS downgraded
FROM next_plan_cte
WHERE start_date <= '2020-12-31'
  AND plan_id = 2 
  AND next_plan = 1

