/*
    stg_customers.sql
    Standardises email casing and city/province formatting so downstream
    models don't have to worry about inconsistent raw data.
*/

with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

cleaned as (
    select
        customer_id,
        customer_name,
        lower(email)                    as email,
        concat(upper(city[1]), lower(city[2:]))  as city,
        upper(province)                 as province,
        cast(signup_date as date)       as signup_date

    from source
    where customer_id is not null
)

select * from cleaned
