/*
    customer_cohort_analysis.sql — Customer Cohort Analysis
    =========================================================
    SKILLS DEMONSTRATED:
    - DATE_TRUNC for grouping by month
    - Window functions: ROW_NUMBER, LAG
    - Self-joins for cohort comparisons
    - CTEs for step-by-step logic

    This answers: "How do customers who signed up in the same month
    compare in terms of order volume and value over time?"
*/

-- CTE 1: Assign each customer to their signup cohort (month)
with customer_cohorts as (
    select
        dc.customer_id,
        dc.customer_name,
        dc.customer_segment,
        date_trunc('month', dc.signup_date)     as cohort_month,
        dc.signup_date

    from main.dim_customers dc
),

-- CTE 2: Get each customer's delivery activity by month
customer_monthly_activity as (
    select
        f.customer_key,
        dc.customer_id,
        date_trunc('month', f.delivery_time)    as activity_month,
        count(*)                                 as delivery_count,
        sum(f.order_amount)                      as total_revenue,
        avg(f.delivery_duration_minutes)         as avg_delivery_time

    from main.fact_deliveries f
    join main.dim_customers dc on f.customer_key = dc.customer_key
    group by f.customer_key, dc.customer_id, date_trunc('month', f.delivery_time)
),

-- CTE 3: Join cohort info with activity
cohort_activity as (
    select
        cc.cohort_month,
        cma.activity_month,
        -- Calculate months since signup (cohort age)
        date_diff('month', cc.cohort_month, cma.activity_month) as months_since_signup,
        count(distinct cc.customer_id)           as active_customers,
        sum(cma.delivery_count)                  as total_deliveries,
        round(sum(cma.total_revenue), 2)         as total_revenue,
        round(avg(cma.avg_delivery_time), 1)     as avg_delivery_time

    from customer_cohorts cc
    inner join customer_monthly_activity cma
        on cc.customer_id = cma.customer_id
    group by cc.cohort_month, cma.activity_month
),

-- CTE 4: Add retention metrics using LAG window function
cohort_with_retention as (
    select
        cohort_month,
        activity_month,
        months_since_signup,
        active_customers,
        total_deliveries,
        total_revenue,

        -- LAG: compare to previous month's active customers
        lag(active_customers) over (
            partition by cohort_month
            order by activity_month
        ) as prev_month_active_customers,

        -- Revenue per active customer
        round(total_revenue / nullif(active_customers, 0), 2) as revenue_per_customer

    from cohort_activity
)

select
    strftime(cohort_month, '%Y-%m')     as cohort,
    strftime(activity_month, '%Y-%m')   as month,
    months_since_signup,
    active_customers,
    total_deliveries,
    total_revenue,
    revenue_per_customer,
    prev_month_active_customers,

    -- Month-over-month retention rate
    case
        when prev_month_active_customers > 0
        then round(100.0 * active_customers / prev_month_active_customers, 1)
        else null
    end as retention_rate_pct

from cohort_with_retention
where months_since_signup >= 0
order by cohort_month, activity_month
