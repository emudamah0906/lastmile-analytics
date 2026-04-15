/*
    dim_date.sql
    Date dimension generated via DuckDB's generate_series. I chose
    a natural key (date_day itself) since dates are already unique
    and readable -- no need for a surrogate here.
    Fiscal year starts in April to match Canadian government FY.
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
        -- Natural key
        date_day                                    as date_key,
        date_day,

        -- Standard date parts
        extract(year from date_day)                 as year,
        extract(month from date_day)                as month,
        extract(day from date_day)                  as day_of_month,
        extract(dow from date_day)                  as day_of_week,  -- 0=Sunday
        extract(quarter from date_day)              as quarter,
        extract(week from date_day)                 as week_of_year,

        -- Pre-formatted strings for BI tools
        strftime(date_day, '%B')                    as month_name,
        strftime(date_day, '%A')                    as day_name,
        strftime(date_day, '%Y-%m')                 as year_month,

        -- Weekend flag for weekday vs weekend analysis
        case
            when extract(dow from date_day) in (0, 6) then true
            else false
        end as is_weekend,

        -- Fiscal year (April start, Canadian FY)
        case
            when extract(month from date_day) >= 4
            then extract(year from date_day)
            else extract(year from date_day) - 1
        end as fiscal_year

    from date_spine
)

select * from enriched
