{{ config(materialized='table') }}

select
    session_id_map.id as session_id,
    dim_date.date_id,
    dim_traffic_source.traffic_source_id,
    dim_page.page_id as landing_page_id,
    dim_geo.geo_id,
    dim_device.device_id,
    int_sessions.user_pseudo_id,
    int_sessions.user_id,
    int_sessions.session_code,
    int_sessions.session_start_timestamp,
    int_sessions.is_new_user,
    int_sessions.is_engaged_session,
    int_sessions.total_engagement_time_msec / 1000 as total_engagement_time_sec
from {{ ref('int_sessions') }} as int_sessions
left join {{ ref('session_id_map') }} as session_id_map
    on {{ business_key_expr(['int_sessions.session_code']) }} = session_id_map.business_key
left join {{ ref('dim_date') }} as dim_date
    on dim_date.date_id = int_sessions.session_date
left join {{ ref('dim_traffic_source') }} as dim_traffic_source
    on {{ business_key_expr(['int_sessions.session_source', 'int_sessions.session_medium', 'int_sessions.session_campaign_name']) }}
     = {{ business_key_expr(['dim_traffic_source.source', 'dim_traffic_source.medium', 'dim_traffic_source.campaign']) }}
left join {{ ref('dim_page') }} as dim_page
    on {{ business_key_expr(['int_sessions.landing_page_path', 'int_sessions.landing_page_title']) }}
     = {{ business_key_expr(['dim_page.page_path', 'dim_page.page_title']) }}
left join {{ ref('dim_geo') }} as dim_geo
    on {{ business_key_expr(['int_sessions.country', 'int_sessions.city']) }}
     = {{ business_key_expr(['dim_geo.country', 'dim_geo.city']) }}
left join {{ ref('dim_device') }} as dim_device
    on {{ business_key_expr(['int_sessions.device_category', 'int_sessions.device_brand', 'int_sessions.device_model']) }}
     = {{ business_key_expr(['dim_device.device_category', 'dim_device.device_brand', 'dim_device.device_model']) }}
