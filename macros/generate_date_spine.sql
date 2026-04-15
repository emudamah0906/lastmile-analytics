/*
    generate_date_spine.sql — Custom dbt Macro
    ============================================
    WHAT IS A MACRO?
    Macros are reusable SQL snippets written in Jinja. Think of them as
    functions in Python — they take inputs and generate SQL.

    This macro generates a series of dates between two dates.
    You can call it in any model: {{ generate_date_spine('2024-01-01', '2026-12-31') }}
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
    cents_to_dollars — Simple utility macro
    ========================================
    Converts cents to dollars with 2 decimal places.
    Usage: {{ cents_to_dollars('amount_cents') }}
*/

{% macro cents_to_dollars(column_name) %}
    round(cast({{ column_name }} as decimal(10,2)) / 100, 2)
{% endmacro %}
