/*
    warehouse_utilization.sql
    Tracks monthly order volume against each warehouse's stated capacity.
    The utilization_alert column flags sites nearing capacity so the ops
    team can plan expansion or rebalance routing.
*/

-- Monthly order volume per warehouse
with monthly_warehouse_orders as (
    select
        dw.warehouse_id,
        dw.warehouse_name,
        dw.city,
        dw.capacity,
        dw.capacity_tier,
        date_trunc('month', f.order_date) as order_month,

        count(distinct f.order_id)              as monthly_orders,
        count(distinct f.delivery_id)           as monthly_deliveries,
        round(sum(f.order_amount), 2)           as monthly_revenue,
        round(avg(f.delivery_duration_minutes), 1) as avg_delivery_time

    from main.fact_deliveries f
    join main.dim_warehouses dw on f.warehouse_key = dw.warehouse_key
    group by dw.warehouse_id, dw.warehouse_name, dw.city,
             dw.capacity, dw.capacity_tier, date_trunc('month', f.order_date)
),

-- Running totals and MoM comparisons
warehouse_trends as (
    select
        *,

        -- Cumulative orders
        sum(monthly_orders) over (
            partition by warehouse_id
            order by order_month
            rows unbounded preceding
        ) as cumulative_orders,

        -- Previous month for MoM calc
        lag(monthly_orders) over (
            partition by warehouse_id
            order by order_month
        ) as prev_month_orders,

        -- Smoothed trend (3-month moving avg)
        round(avg(monthly_orders) over (
            partition by warehouse_id
            order by order_month
            rows between 2 preceding and current row
        ), 0) as orders_3m_moving_avg,

        -- Orders as % of stated capacity
        round(100.0 * monthly_orders / nullif(capacity, 0), 1) as utilization_pct

    from monthly_warehouse_orders
)

select
    warehouse_name,
    city,
    capacity_tier,
    strftime(order_month, '%Y-%m')      as month,
    monthly_orders,
    monthly_deliveries,
    monthly_revenue,
    avg_delivery_time,
    cumulative_orders,
    utilization_pct,
    orders_3m_moving_avg,

    -- Month-over-month growth
    case
        when prev_month_orders > 0
        then round(100.0 * (monthly_orders - prev_month_orders)
                   / prev_month_orders, 1)
        else null
    end as mom_growth_pct,

    -- Flag warehouses that are over capacity
    case
        when utilization_pct > 80 then 'HIGH - Near Capacity'
        when utilization_pct > 50 then 'MEDIUM'
        else 'LOW - Underutilized'
    end as utilization_alert

from warehouse_trends
order by warehouse_name, order_month
