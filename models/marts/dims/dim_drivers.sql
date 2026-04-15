/*
    dim_drivers.sql — Driver Dimension
    ====================================
    This dimension captures driver attributes including their vehicle type.
    The is_ev_driver flag is critical for GoBolt's sustainability reporting.
*/

with drivers as (
    select * from {{ ref('stg_drivers') }}
),

enriched as (
    select
        {{ dbt_utils.generate_surrogate_key(['driver_id']) }} as driver_key,

        driver_id,
        driver_name,
        vehicle_type,
        is_ev_driver,
        hire_date,
        driver_status,

        -- Classify vehicle category for reporting
        case
            when vehicle_type like '%van%'   then 'Van'
            when vehicle_type like '%truck%' then 'Truck'
            when vehicle_type = 'cargo_bike' then 'Cargo Bike'
            else 'Other'
        end as vehicle_category,

        -- Driver tenure
        current_date - hire_date as driver_tenure_days

    from drivers
)

select * from enriched
