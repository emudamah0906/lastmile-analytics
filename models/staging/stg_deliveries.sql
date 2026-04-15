/*
    stg_deliveries.sql
    Type-casts and cleans raw delivery records. delivery_duration_minutes
    comes pre-calculated from the source, so I just cast it here rather
    than re-deriving it from timestamps.
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

        -- Duration already exists in source; just cast it
        cast(delivery_duration_minutes as integer) as delivery_duration_minutes

    from source
    where delivery_id is not null
)

select * from cleaned
