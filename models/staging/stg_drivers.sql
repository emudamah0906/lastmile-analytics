/*
    stg_drivers.sql — Staging model for drivers
    =============================================
    We add a boolean flag is_ev_driver — this reflects GoBolt's focus on
    building North America's largest electric vehicle fleet.
*/

with source as (
    select * from {{ source('raw', 'raw_drivers') }}
),

cleaned as (
    select
        driver_id,
        driver_name,
        vehicle_type,
        -- Derived boolean: is this an electric vehicle?
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
