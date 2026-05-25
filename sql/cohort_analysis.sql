with first_step as
(
  select
    distinct i.order_id
    , customer_unique_id
    -- , order_purchase_timestamp
    , sum(price) over (partition by i.order_id) as spent
    , date_trunc('month',MIN(order_purchase_timestamp) over (partition by customer_unique_id)) as first_purchase_month
    , date_trunc('month',order_purchase_timestamp) as activity_month
  from orders o
  left join order_items i on o.order_id = i.order_id
  left join customers c on o.customer_id = c.customer_id
)
, second_step as
(
  select *
    , (extract(year from activity_month) - extract(year from first_purchase_month)) * 12 +
    (extract(month from activity_month) - extract(month from first_purchase_month)) as month_number
  from first_step
)
, third_step as
(
  select first_purchase_month, month_number
    , count(distinct customer_unique_id) as active_users
    , sum(spent) as spent
  from second_step
  group by 1,2
)
select *
  , active_users::numeric / first_value(active_users) over (partition by first_purchase_month order by month_number) * 100 as retention_rate_pct
from third_step;
