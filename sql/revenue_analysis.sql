-- *** monthly revenue, AOV (average order value), monthly revenue growth ***
select ov.o_month as transaction_month
  , count(distinct ov.order_id) as order_freq
  , sum(ov.price) as revenue
  , round(sum(ov.price) / count(distinct ov.order_id), 2) as aov
  , round(avg(sum(ov.price)) over (), 2) as avg_revenue
  , sum(ov.price) - lag(sum(ov.price)) over () as diff
  , round(100 * (sum(ov.price) - lag(sum(ov.price)) over () )/ lag(sum(ov.price)) over (), 2) as growth_pct
from real_order_view ov
group by transaction_month
order by transaction_month;


-- *** revenue by category ***tambahkan frequncy order
select distinct product_category_name
  , product_category_name_english
  , sum(price) over (partition by product_category_name) as revenue
  , round(100 * sum(price) over (partition by product_category_name) / sum(price) over (), 2) as pctage
from real_order_view ov
order by revenue desc
limit 100;
