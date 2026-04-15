/*
    assert_delivery_duration_positive.sql
    Catches any delivery with zero, negative, or null duration --
    these would skew averages and indicate upstream data issues.
*/

select
    delivery_id,
    delivery_duration_minutes
from {{ ref('fact_deliveries') }}
where delivery_duration_minutes <= 0
   or delivery_duration_minutes is null
