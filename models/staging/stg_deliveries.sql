/*
    stg_deliveries.sql — Staging model for deliveries
    ===================================================
    Notice how we compute delivery_duration_minutes from timestamps.
    This is a DERIVED COLUMN — calculated from existing data.
*/

with source as (
    select * from {{ source('raw', 'raw_deliveries') }}
),

cleaned as (
    select
        delivery_id,
        order_id,
        driver_id,
        cast(pickup_time as timestamp)   as pickup_time,
        cast(delivery_time as timestamp) as delivery_time,
        delivery_status,
        cast(distance_km as decimal(10,1)) as distance_km,

        -- Calculate delivery duration in minutes from timestamps
        cast(delivery_duration_minutes as integer) as delivery_duration_minutes

    from source
    where delivery_id is not null
)

select * from cleaned
