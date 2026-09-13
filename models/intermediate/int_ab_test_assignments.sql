{{ config(materialized='view') }}

select distinct
    coalesce(user_id, user_pseudo_id) || '-' || cast(ga_session_id as string) as session_code,
    test_name,
    page_variant_name as variant
from {{ ref('stg_ga4_events') }}
where event_name = 'page_test'
