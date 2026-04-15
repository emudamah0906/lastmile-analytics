/*
    dim_drivers.sql
    Driver dimension with vehicle category and tenure. I added
    vehicle_category to simplify grouping in reports (van/truck/bike)
    without repeating CASE logic in every query.
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

        -- Coarser grouping for BI dashboards
        case
            when vehicle_type like '%van%'   then 'Van'
            when vehicle_type like '%truck%' then 'Truck'
            when vehicle_type = 'cargo_bike' then 'Cargo Bike'
            else 'Other'
        end as vehicle_category,

        -- Tenure in days for experience-based analysis
        current_date - hire_date as driver_tenure_days

    from drivers
)

select * from enriched
