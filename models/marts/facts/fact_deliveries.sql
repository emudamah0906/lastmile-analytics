/*
    fact_deliveries.sql — Delivery Fact Table (INCREMENTAL)
    ========================================================
    WHAT IS AN INCREMENTAL MODEL?
    Instead of rebuilding the entire table every run, incremental models
    only process NEW or CHANGED rows. This is critical for:
    - Large datasets (billions of rows) — saves compute cost
    - Near-real-time pipelines — faster refresh times

    HOW IT WORKS:
    1. First run: builds the full table (like a regular table model)
    2. Subsequent runs: only inserts rows where delivery_time > max existing
    3. The is_incremental() macro returns false on first run, true after

    Star Schema Layout:
                    dim_date
                       |
    dim_customers -- FACT_DELIVERIES -- dim_drivers
                       |
                  dim_warehouses
*/

{{
    config(
        materialized='incremental',
        unique_key='delivery_key'
    )
}}

with deliveries as (
    select * from {{ ref('int_orders_deliveries_joined') }}

    -- INCREMENTAL FILTER: only get new deliveries since last run
    {% if is_incremental() %}
    where delivery_time > (select max(delivery_time) from {{ this }})
    {% endif %}
),

-- Look up dimension keys
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
        -- Surrogate key for the fact row
        {{ dbt_utils.generate_surrogate_key(['del.delivery_id']) }} as delivery_key,

        -- Foreign keys to dimensions (this is what makes it a STAR schema)
        dc.customer_key,
        dd.driver_key,
        dw.warehouse_key,
        del.delivery_date                       as date_key,

        -- Degenerate dimensions (IDs kept for drill-down)
        del.delivery_id,
        del.order_id,

        -- Measures (the numbers you'll aggregate in reports)
        del.delivery_duration_minutes,
        del.distance_km,
        del.order_amount,
        del.item_count,

        -- Boolean measures
        del.is_on_time,
        dd.is_ev_driver                         as is_ev_delivery,

        -- Status
        del.delivery_status,
        del.order_status,

        -- Timestamps for detailed analysis
        del.order_date,
        del.pickup_time,
        del.delivery_time

    from deliveries del
    left join dim_customers dc   on del.customer_id  = dc.customer_id
    left join dim_drivers dd     on del.driver_id    = dd.driver_id
    left join dim_warehouses dw  on del.warehouse_id = dw.warehouse_id
)

select * from fact
