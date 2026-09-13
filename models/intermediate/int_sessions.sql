{{ config(materialized='view') }}

with aggregated as (

    select
        session_identity_key || '-' || cast(ga_session_id as string) as session_code, -- session_identity_key (computed once in stg_ga4_events) already handles the consent-denied fallback, including device/source tiebreakers
        user_pseudo_id,
        user_id,
        stream_id,
        ga_session_number,
        session_source,
        session_medium,
        session_campaign_name,
        array_agg(struct(device_category, device_brand, device_model, device_marketing_name) order by event_timestamp asc limit 1)[offset(0)] as device_event, -- all 4 taken from the same first-event row, not independently per column -- device_category can change mid-session (e.g. browser dev tools device emulation) without a new GA4 session starting, so 4 separate MIN()s could mix fields from different rows into a combination that never existed
        min(event_timestamp) as session_start_timestamp,
        min(event_date) as session_date,
        array_agg(struct(page_location, page_title) order by event_timestamp asc limit 1)[offset(0)] as landing_event,
        array_agg(struct(country, city) order by event_timestamp asc limit 1)[offset(0)] as geo_event, -- both taken from the same first-event row -- geo is IP-derived per hit and could vary mid-session, same "don't mix rows" reasoning as device_event above
        sum(engagement_time_msec) as total_engagement_time_msec,
        max(session_engaged) = 1 as is_engaged_session,
        min(event_timestamp) = min(user_first_touch_timestamp) as is_new_user -- device-level only; not accurate once user_id is configured across devices
    from {{ ref('int_consented_events') }}
    group by
        session_identity_key,
        user_pseudo_id,
        user_id,
        stream_id,
        ga_session_id,
        ga_session_number, -- constant per session (GA4-generated sequence number), safe to group by directly
        session_source, -- session_traffic_source_last_click is fixed at session start by GA4 itself -- safe to group by directly, not an aggregation pick
        session_medium,
        session_campaign_name

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
    device_event.device_category,
    device_event.device_brand,
    device_event.device_model,
    device_event.device_marketing_name,
    geo_event.country,
    geo_event.city,
    total_engagement_time_msec,
    is_engaged_session,
    is_new_user
from aggregated
