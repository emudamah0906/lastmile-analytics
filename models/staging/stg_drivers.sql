/*
    stg_drivers.sql
    I derive is_ev_driver at this layer so every downstream model can
    slice by EV vs gas without re-implementing the logic.
*/

with source as (
    select * from {{ source('raw', 'raw_drivers') }}
),

cleaned as (
    select
        driver_id,
        driver_name,
        vehicle_type,
        -- EV flag used heavily in sustainability reporting
        case
            when vehicle_type like 'electric%' then true
            else false
        end as is_ev_driver,
        cast(hire_date as date)         as hire_date,
        driver_status

    from source
    where driver_id is not null
)

select * from cleaned
