/*
    delivery_performance.sql — Delivery Performance Analysis
    ==========================================================
    SKILLS DEMONSTRATED:
    - CTEs (Common Table Expressions) for readable, modular queries
    - Window functions: AVG() OVER, running averages
    - CASE statements for conditional logic
    - GROUP BY with multiple dimensions

    This query answers: "How does delivery performance vary by warehouse,
    vehicle type, and day of week?"
*/

-- CTE 1: Base delivery metrics joined with dimensions
with delivery_metrics as (
    select
        f.delivery_duration_minutes,
        f.distance_km,
        f.order_amount,
        f.is_on_time,
        f.is_ev_delivery,
        f.delivery_status,
        dw.warehouse_name,
        dw.city as warehouse_city,
        dw.capacity_tier,
        dd.driver_name,
        dd.vehicle_type,
        dd.vehicle_category,
        dt.day_name,
        dt.is_weekend,
        dt.month_name,
        dt.year

    from main.fact_deliveries f
    join main.dim_warehouses dw  on f.warehouse_key = dw.warehouse_key
    join main.dim_drivers dd     on f.driver_key    = dd.driver_key
    join main.dim_date dt        on f.date_key      = dt.date_key
),

-- CTE 2: Performance by warehouse and vehicle type
warehouse_vehicle_performance as (
    select
        warehouse_city,
        vehicle_category,
        is_ev_delivery,

        count(*)                                        as total_deliveries,
        round(avg(delivery_duration_minutes), 1)        as avg_duration_min,
        round(avg(distance_km), 1)                      as avg_distance_km,
        round(avg(order_amount), 2)                     as avg_order_value,
        round(100.0 * sum(case when is_on_time then 1 else 0 end)
              / count(*), 1)                            as on_time_pct,

        -- Window function: compare each group to the overall average
        round(avg(delivery_duration_minutes) over (), 1) as overall_avg_duration

    from delivery_metrics
    where delivery_status = 'delivered'
    group by warehouse_city, vehicle_category, is_ev_delivery
),

-- CTE 3: Day of week patterns
day_of_week_patterns as (
    select
        day_name,
        is_weekend,
        count(*)                                        as total_deliveries,
        round(avg(delivery_duration_minutes), 1)        as avg_duration_min,
        round(100.0 * sum(case when is_on_time then 1 else 0 end)
              / count(*), 1)                            as on_time_pct

    from delivery_metrics
    where delivery_status = 'delivered'
    group by day_name, is_weekend
)

-- Final output: Warehouse + vehicle performance
select
    warehouse_city,
    vehicle_category,
    case when is_ev_delivery then 'Electric' else 'Gas/Other' end as fuel_type,
    total_deliveries,
    avg_duration_min,
    avg_distance_km,
    avg_order_value,
    on_time_pct,
    overall_avg_duration,
    round(avg_duration_min - overall_avg_duration, 1) as diff_from_avg

from warehouse_vehicle_performance
order by warehouse_city, vehicle_category
