{{ config(materialized='table') }}

with events as (

    select
        stg.user_pseudo_id,
        stg.user_id,
        stg.event_date,
        stg.event_timestamp,
        stg.event_name,
        stg.event_value,
        split(stg.page_location, '?')[offset(0)] as page_path,
        stg.page_title,
        coalesce(stg.user_id, stg.user_pseudo_id) || '-' || cast(stg.ga_session_id as string) as session_code
    from {{ ref('stg_ga4_events') }} as stg

)

select
    {{ dbt_utils.generate_surrogate_key(['events.user_pseudo_id', 'events.event_timestamp', 'events.event_name']) }} as event_id,
    session_id_map.id as session_id,
    dim_date.date_id,
    dim_page.page_id,
    events.user_pseudo_id,
    events.user_id,
    events.event_name,
    events.event_timestamp,
    events.event_value,
    events.event_name in (
        select event_name from {{ ref('seed_conversion_events') }} where is_default_conversion
    ) as is_conversion
from events
left join {{ ref('session_id_map') }} as session_id_map
    on {{ business_key_expr(['events.session_code']) }} = session_id_map.business_key
left join {{ ref('dim_date') }} as dim_date
    on dim_date.date_id = events.event_date
left join {{ ref('dim_page') }} as dim_page
    on {{ business_key_expr(['events.page_path', 'events.page_title']) }}
     = {{ business_key_expr(['dim_page.page_path', 'dim_page.page_title']) }}
