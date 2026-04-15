/*
    stg_orders.sql
    Cleans and type-casts raw order data. No joins or business logic here --
    I keep staging models as thin 1:1 mirrors of each source table so
    downstream changes are easy to trace.
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
