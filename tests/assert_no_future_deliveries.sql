/*
    assert_no_future_deliveries.sql — Data Quality Test
    =====================================================
    Ensures no delivery has a timestamp too far in the future.
    We allow a 7-day buffer for scheduled/planned deliveries.
*/

select
    delivery_id,
    delivery_time
from {{ ref('fact_deliveries') }}
where delivery_time > current_timestamp + interval 7 day
