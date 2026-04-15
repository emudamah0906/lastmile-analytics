/*
    assert_no_future_deliveries.sql
    Flags deliveries timestamped more than 7 days into the future.
    The 7-day buffer accounts for pre-scheduled routes.
*/

select
    delivery_id,
    delivery_time
from {{ ref('fact_deliveries') }}
where delivery_time > current_timestamp + interval 7 day
