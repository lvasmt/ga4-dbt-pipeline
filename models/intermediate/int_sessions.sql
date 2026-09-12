{{ config(materialized='view') }}

with aggregated as (

    select
        coalesce(user_id, user_pseudo_id) || '-' || cast(ga_session_id as string) as session_code,
        user_pseudo_id,
        user_id,
        min(ga_session_number) as ga_session_number,
        min(event_timestamp) as session_start_timestamp,
        min(event_date) as session_date,
        array_agg(struct(page_location, page_title) order by event_timestamp limit 1)[offset(0)] as landing_event,
        any_value(session_source) as session_source,
        any_value(session_medium) as session_medium,
        any_value(session_campaign_name) as session_campaign_name, -- ANY_VALUE assumes attribution is constant within a session; not fixed yet if it changes mid-session
        any_value(device_category) as device_category,
        any_value(country) as country,
        any_value(city) as city,
        sum(engagement_time_msec) as total_engagement_time_msec,
        max(session_engaged) = 1 as is_engaged_session,
        min(event_timestamp) = any_value(user_first_touch_timestamp) as is_new_user -- device-level only; not accurate once user_id is configured across devices
    from {{ ref('stg_ga4_events') }}
    group by
        user_pseudo_id,
        user_id,
        ga_session_id

)

select
    session_code,
    user_pseudo_id,
    user_id,
    ga_session_number,
    session_start_timestamp,
    session_date,
    split(landing_event.page_location, '?')[offset(0)] as landing_page_path,
    landing_event.page_title as landing_page_title,
    session_source,
    session_medium,
    session_campaign_name,
    device_category,
    country,
    city,
    total_engagement_time_msec,
    is_engaged_session,
    is_new_user
from aggregated
