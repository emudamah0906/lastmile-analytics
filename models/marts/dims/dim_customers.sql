/*
    dim_customers.sql — Customer Dimension
    ========================================
    WHAT IS A DIMENSION TABLE?
    Dimension tables contain DESCRIPTIVE attributes — the "who, what, where"
    of your data. They answer questions like:
    - Who is this customer?
    - Where are they located?
    - How long have they been with us?

    Dimensions are typically WIDE (many columns) and SHORT (fewer rows).
    They are joined to fact tables via foreign keys.
*/

with customers as (
    select * from {{ ref('stg_customers') }}
),

enriched as (
    select
        -- Surrogate key: a hash-based unique ID (best practice in dimensional modeling)
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,

        customer_id,
        customer_name,
        email,
        city,
        province,
        signup_date,

        -- Derived fields: add business context
        current_date - signup_date as customer_tenure_days,

        case
            when current_date - signup_date < 90  then 'New (< 90 days)'
            when current_date - signup_date < 365 then 'Growing (90-365 days)'
            else 'Established (1+ years)'
        end as customer_segment

    from customers
)

select * from enriched
