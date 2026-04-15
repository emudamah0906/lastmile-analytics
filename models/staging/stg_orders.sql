/*
    stg_orders.sql — Staging model for orders
    ==========================================
    WHAT IS A STAGING MODEL?
    Staging models are the first transformation layer. They:
    1. Rename columns to consistent naming conventions
    2. Cast data types (strings to dates, etc.)
    3. Filter out bad/null records
    4. Do NOT join tables or add business logic — that comes later

    The source() function references tables defined in sources.yml
*/

with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

cleaned as (
    select
        order_id,
        customer_id,
        warehouse_id,
        cast(order_date as timestamp)   as order_date,
        order_status,
        cast(total_amount as decimal(10,2)) as order_amount,
        cast(item_count as integer)     as item_count

    from source
    where order_id is not null
)

select * from cleaned
