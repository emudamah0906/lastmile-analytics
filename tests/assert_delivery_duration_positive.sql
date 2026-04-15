/*
    assert_delivery_duration_positive.sql — Custom Singular Test
    ==============================================================
    WHAT IS A CUSTOM TEST?
    Custom tests are SQL queries that return FAILING rows.
    If the query returns 0 rows → test PASSES.
    If the query returns any rows → test FAILS (those rows are bad data).

    This test ensures no delivery has a negative or zero duration,
    which would indicate a data quality issue.
*/

select
    delivery_id,
    delivery_duration_minutes
from {{ ref('fact_deliveries') }}
where delivery_duration_minutes <= 0
   or delivery_duration_minutes is null
