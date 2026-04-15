/*
    int_orders_deliveries_joined.sql — Intermediate Model
    ======================================================
    WHAT IS AN INTERMEDIATE MODEL?
    Intermediate models sit between staging and marts. They:
    - Join related staging tables together
    - Apply business logic
    - Are materialized as EPHEMERAL (not stored as tables, inlined as CTEs)

    This model joins orders with their deliveries to create a unified view
    of the "Order Lifecycle" — a key concept in logistics data modeling.
*/

with orders as (
    select * from {{ ref('stg_orders') }}
),

deliveries as (
    select * from {{ ref('stg_deliveries') }}
),

joined as (
    select
        -- Delivery fields
        d.delivery_id,
        d.driver_id,
        d.pickup_time,
        d.delivery_time,
        d.delivery_status,
        d.distance_km,
        d.delivery_duration_minutes,

        -- Order fields
        o.order_id,
        o.customer_id,
        o.warehouse_id,
        o.order_date,
        o.order_status,
        o.order_amount,
        o.item_count,

        -- Derived: was this delivery on time? (under 60 minutes = on time)
        case
            when d.delivery_duration_minutes <= 60 then true
            else false
        end as is_on_time,

        -- Date key for joining to dim_date
        cast(d.delivery_time as date) as delivery_date

    from deliveries d
    inner join orders o
        on d.order_id = o.order_id
)

select * from joined
