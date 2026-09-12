{{ config(materialized='table') }}

with date_spine as (
    select date_day
    from unnest(generate_date_array('2020-01-01', '2035-12-31', interval 1 day)) as date_day
)

select
    format_date('%Y%m%d', date_day) as date_id,
    date_day as calendar_date,
    mod(extract(dayofweek from date_day) + 5, 7) + 1 as day_of_week_number, -- Monday=1 ... Sunday=7, to match the Monday-based week_start_date below
    format_date('%A', date_day) as day_of_week_description,
    date_trunc(date_day, week(monday)) as week_start_date,
    extract(month from date_day) as month,
    extract(quarter from date_day) as quarter,
    extract(year from date_day) as year,
    extract(dayofweek from date_day) in (1, 7) as is_weekend
from date_spine
