/*
    stg_warehouses.sql — Staging model for warehouses
*/

with source as (
    select * from {{ source('raw', 'raw_warehouses') }}
),

cleaned as (
    select
        warehouse_id,
        warehouse_name,
        concat(upper(city[1]), lower(city[2:]))  as city,
        upper(province)                 as province,
        cast(capacity as integer)       as capacity,
        cast(opened_date as date)       as opened_date

    from source
    where warehouse_id is not null
)

select * from cleaned
