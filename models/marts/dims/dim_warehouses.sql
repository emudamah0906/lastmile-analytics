/*
    dim_warehouses.sql — Warehouse Dimension
    ==========================================
    Warehouses (fulfillment centers) are where orders are picked and shipped.
    The capacity_tier helps with operational planning.
*/

with warehouses as (
    select * from {{ ref('stg_warehouses') }}
),

enriched as (
    select
        {{ dbt_utils.generate_surrogate_key(['warehouse_id']) }} as warehouse_key,

        warehouse_id,
        warehouse_name,
        city,
        province,
        capacity,
        opened_date,

        -- Capacity tier for grouping in reports
        case
            when capacity <= 500  then 'Small'
            when capacity <= 1000 then 'Medium'
            when capacity <= 2000 then 'Large'
            else 'Extra Large'
        end as capacity_tier

    from warehouses
)

select * from enriched
