/*
    dim_date.sql — Date Dimension
    ===============================
    EVERY star schema needs a date dimension. It lets you:
    - Group by day, week, month, quarter, year
    - Filter by weekday vs weekend
    - Compare year-over-year performance

    This generates a row for every day in a date range using
    DuckDB's generate_series function.
*/

with date_spine as (
    select
        cast(unnest(generate_series(
            date '2024-01-01',
            date '2026-12-31',
            interval 1 day
        )) as date) as date_day
),

enriched as (
    select
        -- The date itself is the key (natural key — no surrogate needed for dates)
        date_day                                    as date_key,
        date_day,

        -- Date parts
        extract(year from date_day)                 as year,
        extract(month from date_day)                as month,
        extract(day from date_day)                  as day_of_month,
        extract(dow from date_day)                  as day_of_week,  -- 0=Sunday
        extract(quarter from date_day)              as quarter,
        extract(week from date_day)                 as week_of_year,

        -- Formatted strings for BI tools
        strftime(date_day, '%B')                    as month_name,
        strftime(date_day, '%A')                    as day_name,
        strftime(date_day, '%Y-%m')                 as year_month,

        -- Boolean flags
        case
            when extract(dow from date_day) in (0, 6) then true
            else false
        end as is_weekend,

        -- Fiscal year (assuming April start — common in Canada)
        case
            when extract(month from date_day) >= 4
            then extract(year from date_day)
            else extract(year from date_day) - 1
        end as fiscal_year

    from date_spine
)

select * from enriched
