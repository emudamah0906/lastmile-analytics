/*
    int_orders_deliveries_joined.sql
    Joins orders to their delivery events and derives is_on_time.
    I keep this as an ephemeral intermediate model so the fact table
    doesn't have to carry all the join + business-logic complexity.
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

        -- Business rule: <= 60 min = on time (agreed threshold with ops team)
        case
            when d.delivery_duration_minutes <= 60 then true
            else false
        end as is_on_time,

        -- Truncated to date for dim_date join
        cast(d.delivery_time as date) as delivery_date

    from deliveries d
    inner join orders o
        on d.order_id = o.order_id
)

select * from joined
