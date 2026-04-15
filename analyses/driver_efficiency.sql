/*
    driver_efficiency.sql
    Ranks drivers by on-time %, volume, and failure rate. I use NTILE
    to bucket into performance quartiles so ops can quickly flag the
    bottom 25% for coaching. The 10-delivery minimum filters out
    drivers with too little data to rank meaningfully.
*/

-- Per-driver aggregates
with driver_metrics as (
    select
        dd.driver_id,
        dd.driver_name,
        dd.vehicle_type,
        dd.vehicle_category,
        dd.is_ev_driver,
        dd.driver_tenure_days,

        count(*)                                        as total_deliveries,
        round(avg(f.delivery_duration_minutes), 1)      as avg_duration_min,
        round(avg(f.distance_km), 1)                    as avg_distance_km,
        round(sum(f.order_amount), 2)                   as total_revenue_delivered,

        -- Core KPIs
        round(100.0 * sum(case when f.is_on_time then 1 else 0 end)
              / count(*), 1)                            as on_time_pct,

        -- Failure rate (ops watches this closely)
        round(100.0 * sum(case when f.delivery_status = 'failed' then 1 else 0 end)
              / count(*), 1)                            as failure_rate_pct

    from main.fact_deliveries f
    join main.dim_drivers dd on f.driver_key = dd.driver_key
    group by dd.driver_id, dd.driver_name, dd.vehicle_type,
             dd.vehicle_category, dd.is_ev_driver, dd.driver_tenure_days
    having count(*) >= 10  -- Filter out low-volume drivers
),

-- Rankings and quartile bucketing
ranked_drivers as (
    select
        *,

        rank() over (order by on_time_pct desc)         as on_time_rank,
        dense_rank() over (order by total_deliveries desc) as volume_rank,
        ntile(4) over (order by on_time_pct desc)       as performance_quartile,

        -- Per-category rank for EV vs gas comparisons
        rank() over (
            partition by vehicle_category
            order by on_time_pct desc
        ) as rank_within_category

    from driver_metrics
)

select
    driver_name,
    vehicle_type,
    case when is_ev_driver then 'EV' else 'Gas' end as fuel_type,
    total_deliveries,
    avg_duration_min,
    avg_distance_km,
    on_time_pct,
    failure_rate_pct,
    total_revenue_delivered,

    -- Rankings
    on_time_rank,
    volume_rank,
    rank_within_category,

    -- Performance tier based on quartile
    case performance_quartile
        when 1 then 'Top 25%'
        when 2 then 'Above Average'
        when 3 then 'Below Average'
        when 4 then 'Bottom 25%'
    end as performance_tier

from ranked_drivers
order by on_time_rank
