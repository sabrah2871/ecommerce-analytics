-- *** Top products and its category ***
select distinct (product_id), product_category_name, product_category_name_english,
  count(product_id) over (partition by product_id) as qty
from real_order_view
order by qty desc
limit 20;

-- *** Basket size ***
-- ABS (average basket size) = total number of units sold / total number of transactions
select round(count(*)::numeric / count(distinct order_id)::numeric, 2) as basket_size
from real_order_view;

-- *** Frequently bought together ***
with temp_table as (
  select order_id, product_id
  from real_order_view
  group by order_id, product_id
),
total_txn as (
  select count(distinct order_id) as total from temp_table
),
pairs as (
  select
    t1.product_id as product_1,
    t2.product_id as product_2,
    count(*) as pair_count
  from temp_table t1
  join temp_table t2
    on t1.order_id = t2.order_id
    and t1.product_id < t2.product_id
  group by t1.product_id, t2.product_id
)
select
  p.*,
  p.pair_count * 1.0 / t.total as support
from pairs p
cross join total_txn t
order by support desc
limit 30;


-- checking result of Frequently Bought Together query
(
select order_id
from real_order_view
where product_id = '36f60d45225e60c7da4558b070ce4b60' -- change with first element of id pairs from FBT query result
)
intersect
(
select order_id
from real_order_view
where product_id = 'e53e557d5a159f5aa2c5e995dfdf244b' -- change with second element of id pairs from FBT query result
);
