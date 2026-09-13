{{ config(
    materialized='incremental',
    unique_key=['event_business_key'],
    incremental_strategy='merge',
    partition_by={'field': 'event_date', 'data_type': 'date'}
) }}

with base as (

    select
        parse_date('%Y%m%d', event_date) as event_date, -- GA4 exports this as a STRING (YYYYMMDD); converted to a real DATE once, here, so nothing downstream has to format/match strings
        event_timestamp,
        event_name,
        user_pseudo_id,
        coalesce(user_pseudo_id, concat('anonymous-', cast(stream_id as string))) as event_identity_key, -- non-null stand-in for MERGE matching; NULL user_pseudo_id (consent denied) would otherwise never match itself on rerun, since NULL = NULL is never true in SQL
        user_id, -- only populated if this GA4 property has User-ID configured; null otherwise
        user_first_touch_timestamp,
        stream_id,
        {{get_ga4_repeated_field('event_params','ga_session_id','int_value')}} as ga_session_id,
        {{get_ga4_repeated_field('event_params','ga_session_number','int_value')}} as ga_session_number,
        {{get_ga4_repeated_field('event_params','page_location','string_value')}} as page_location,
        {{get_ga4_repeated_field('event_params','page_title','string_value')}} as page_title,
        {{get_ga4_repeated_field('event_params','engagement_time_msec','int_value')}} as engagement_time_msec,
        {{get_ga4_repeated_field('event_params','session_engaged','int_value')}} as session_engaged,
        {{get_ga4_repeated_field('event_params','value','double_value')}} as event_value, -- revenue/value param; not currently used on this site but kept for future events that carry it
        {{get_ga4_repeated_field('event_params','test_name','string_value')}} as test_name, -- only present on 'page_test' events, null otherwise
        {{get_ga4_repeated_field('event_params','page_variant_name','string_value')}} as page_variant_name, -- only present on 'page_test' events, null otherwise
        device.category as device_category,
        device.mobile_brand_name as device_brand,
        device.mobile_model_name as device_model,
        device.mobile_marketing_name as device_marketing_name,
        privacy_info.analytics_storage as consent_analytics_storage, -- 'Yes'/'No'/null (Advanced Consent Mode); null means no consent signal, not denial
        privacy_info.ads_storage as consent_ads_storage,
        geo.country as country,
        geo.city as city,
        collected_traffic_source.manual_source as manual_source,
        collected_traffic_source.manual_medium as manual_medium,
        collected_traffic_source.manual_campaign_name as manual_campaign_name,
        session_traffic_source_last_click.manual_campaign.source as session_source,
        session_traffic_source_last_click.manual_campaign.medium as session_medium,
        session_traffic_source_last_click.manual_campaign.campaign_name as session_campaign_name
    from
        {{source('ga4_export','events_*')}}
    {% if is_incremental() %}
    where _TABLE_SUFFIX >= (
        select format_date('%Y%m%d', date_sub(max(event_date), interval 3 day))
        from {{ this }}
    )
    {% endif %}

)

select
    *,
    {{ business_key_expr(['event_identity_key', 'event_timestamp', 'event_name', 'device_category', 'country', 'city']) }} as event_business_key -- null-safe composite MERGE key; device/geo are extra tiebreakers on top of the identity fix, not a replacement for it
from base
