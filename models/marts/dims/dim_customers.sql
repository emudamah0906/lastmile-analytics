/*
    dim_customers.sql
    Customer dimension with surrogate key, tenure, and segment.
    I chose to derive customer_segment here so the dashboard and
    any BI tool can filter by segment without re-calculating it.
*/

with customers as (
    select * from {{ ref('stg_customers') }}
),

enriched as (
    select
        -- Surrogate key (hash-based)
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,

        customer_id,
        customer_name,
        email,
        city,
        province,
        signup_date,

        -- Tenure and segment for self-service analytics
        current_date - signup_date as customer_tenure_days,

        case
            when current_date - signup_date < 90  then 'New (< 90 days)'
            when current_date - signup_date < 365 then 'Growing (90-365 days)'
            else 'Established (1+ years)'
        end as customer_segment

    from customers
)

select * from enriched
