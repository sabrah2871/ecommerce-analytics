-- *** Total customers and Repeat purchase rate (RPR)***
select
  count(case when is_repeat = 1 and is_existing = 1 then customer_unique_id end) as repeat_customers,
  count(case when is_existing = 1 then customer_unique_id end) as total_customers,
  count(case when is_repeat = 1 and is_existing = 1 then customer_unique_id end)::numeric / count(case when is_existing = 1 then customer_unique_id end) as rpr_pct
  , sum(case when is_repeat = 1 and is_existing = 1  then amount end) as rpt_revenue
  , round(sum(case when is_repeat = 1 and is_existing = 1 then amount end) / count(case when is_repeat = 1 and is_existing = 1 then customer_unique_id end), 2) as spent_per_rpt
  , round(sum(case when is_repeat = 0 and is_existing = 1 then amount end) / count(case when is_repeat = 0 and is_existing = 1 then customer_unique_id end), 2) as spent_per_onetime
from clv_view;


-- *** Top 10% customers (Purchase Frequency)
select customer_unique_id, order_freq
from (
  select customer_unique_id
    , order_freq
    , percent_rank() over (order by urutan) as rank_pct
  from
    (select customer_unique_id, order_freq, row_number() over () as urutan
    from
      (select *
      from clv_view
      order by order_freq desc))
) as ranked_users
where rank_pct <= 0.10;


-- *** Top 10% customers (Purchase Items)
select customer_unique_id, product_id
from (
  select customer_unique_id
    , product_id
    , percent_rank() over (order by urutan) as rank_pct
  from
    (select customer_unique_id, product_id, row_number() over () as urutan
    from
      (select *
      from clv_view
      order by product_id desc))
) as ranked_users
where rank_pct <= 0.10;

-- *** Top 10% customers (Purchase Quantity)
select customer_unique_id, qty
from (
  select customer_unique_id
    , qty
    , percent_rank() over (order by urutan) as rank_pct
  from
    (select customer_unique_id, qty, row_number() over () as urutan
    from
      (select *
      from clv_view
      order by qty desc))
) as ranked_users
where rank_pct <= 0.10;

-- *** Top 10% customers (Purchase Amount)===========================
select customer_unique_id, amount
from (
  select customer_unique_id
    , amount
    , percent_rank() over (order by urutan) as rank_pct
  from
    (select customer_unique_id, amount, row_number() over () as urutan
    from
      (select *
      from clv_view
      order by amount desc))
) as ranked_users
where rank_pct <= 0.10;


-- *** Customer Lifetime Value ***
select customer_unique_id, first_order, last_order, lifespan_day, order_freq, amount, aov, clv
from clv_view
where last_order_life > 90 and is_existing = 1 and is_inactive = 1 -- churn and exclude 1 time order
order by clv desc
limit 30;

-- *** Churn rate ***
select
  sum(is_inactive * is_existing)::numeric / count(customer_unique_id) as churn_rate
from
  (select customer_unique_id
    , case when (max(curr_date)::date - min(order_purchase_timestamp)::date) > 30 then 1 else 0 end as is_existing
    , case when (max(curr_date)::date - max(order_purchase_timestamp)::date) > 90 then 1 else 0 end as is_inactive
  from joined_tables
  group by customer_unique_id);
