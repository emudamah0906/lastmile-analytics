/*
    fact_deliveries.sql — Incremental delivery fact table
    I made this incremental because in production the deliveries table
    grows fast and full rebuilds would be wasteful. On first run it
    builds the full table; after that it only picks up new rows by
    delivery_time.
*/

{{
    config(
        materialized='incremental',
        unique_key='delivery_key'
    )
}}

with deliveries as (
    select * from {{ ref('int_orders_deliveries_joined') }}

    -- Only pick up rows newer than the last run
    {% if is_incremental() %}
    where delivery_time > (select max(delivery_time) from {{ this }})
    {% endif %}
),

-- Dimension key lookups
dim_customers as (
    select customer_key, customer_id from {{ ref('dim_customers') }}
),

dim_drivers as (
    select driver_key, driver_id, is_ev_driver from {{ ref('dim_drivers') }}
),

dim_warehouses as (
    select warehouse_key, warehouse_id from {{ ref('dim_warehouses') }}
),

fact as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['del.delivery_id']) }} as delivery_key,

        -- Dimension foreign keys
        dc.customer_key,
        dd.driver_key,
        dw.warehouse_key,
        del.delivery_date                       as date_key,

        -- Degenerate dimensions (kept for drill-down)
        del.delivery_id,
        del.order_id,

        -- Measures
        del.delivery_duration_minutes,
        del.distance_km,
        del.order_amount,
        del.item_count,

        -- Flags
        del.is_on_time,
        dd.is_ev_driver                         as is_ev_delivery,

        -- Statuses
        del.delivery_status,
        del.order_status,

        -- Raw timestamps for drill-down
        del.order_date,
        del.pickup_time,
        del.delivery_time

    from deliveries del
    left join dim_customers dc   on del.customer_id  = dc.customer_id
    left join dim_drivers dd     on del.driver_id    = dd.driver_id
    left join dim_warehouses dw  on del.warehouse_id = dw.warehouse_id
)

select * from fact
