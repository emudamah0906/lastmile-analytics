/*
    generate_date_spine.sql
    Reusable macro for producing a continuous date range.
    I use this instead of dbt_utils.date_spine because DuckDB's
    generate_series is simpler and avoids the adapter compatibility issues.
*/

{% macro generate_date_spine(start_date, end_date) %}

    select
        cast(unnest(generate_series(
            date '{{ start_date }}',
            date '{{ end_date }}',
            interval 1 day
        )) as date) as date_day

{% endmacro %}


/*
    cents_to_dollars
    Utility for converting cent-denominated amounts to dollars.
*/

{% macro cents_to_dollars(column_name) %}
    round(cast({{ column_name }} as decimal(10,2)) / 100, 2)
{% endmacro %}
