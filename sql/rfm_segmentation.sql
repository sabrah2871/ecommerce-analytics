-- 1. define curr_date
--    max(o.order_purchase_timestamp) over ()
-- 2. define specific time: customer who have purchase in the last 24 months since curr_date
-- 3. seperate analyse data for wholesales (enterprise customer/B2B) and retail (individual custtomer/B2C)
-- 4. "New Customer" whose first purchase was within the last 30 days, so don't get lumped in with "At Risk" custtomers.

-- RFM query
select *
  , case
    when r_score = 5 and last_purchase::date - first_purchase::date <= 30 then 'New Customer' -- 4. new segment
    when r_score = 5 and f_score = 5 and m_score >= 4 then 'VIP'
    when r_score = 1 and f_score = 1 then 'Lost'
    when r_score >= 3 and f_score = 5 then 'Loyal'
    when r_score <= 2 and f_score <= 2 then 'At Risk'
    end as rfm_segment
from (
  with customer_stats​ as (
    select customer_unique_id
      , min(order_purchase_timestamp) as first_purchase
      , max(order_purchase_timestamp) as last_purchase
      , count(order_id) as total_orders
      , sum(price) as total_spent
      , max(curr_date) as curr_date -- 1. define curr_date
    from joined_tables
    group by customer_unique_id
    having (min(curr_date)::date - min(order_purchase_timestamp)::date) <= 730 -- 2. filter to only the last 730 days or 24 months
  )
  , rfm_raw as (
    select *
      , DATE_PART('day', curr_date::timestamp - last_purchase) as recency
    from customer_stats​
  )
  select customer_unique_id
    , first_purchase, last_purchase, recency, total_orders, total_spent
    , case
        when recency <= 30 then 5
        when recency <= 50 then 4
        when recency <= 70 then 3
        when recency <= 90 then 2
        when recency > 90 then 1
        end as r_score
    , case
        when total_orders <= 1 then 1
        when total_orders <= 5 then 2
        when total_orders <= 9 then 3
        when total_orders <= 12 then 4
        when total_orders > 12 then 5 
        end as f_score
    , ntile(5) over (order by total_spent asc) as m_score -- higher value -> higher score
  from rfm_raw);

