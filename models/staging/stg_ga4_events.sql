select 
    event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    stream_id, 
    {{get_ga4_repeated_field('event_params','ga_session_id','int_value')}} as ga_session_id, 
    {{get_ga4_repeated_field('event_params','ga_session_number','int_value')}} as ga_session_number, 
    {{get_ga4_repeated_field('event_params','page_location','string_value')}} as page_location, 
    {{get_ga4_repeated_field('event_params','page_title','string_value')}} as page_title, 
    device.category as device_category, 
    geo.country as country, 
    geo.city as city, 
    collected_traffic_source.manual_source as manual_source, 
    collected_traffic_source.manual_medium as manual_medium, 
    collected_traffic_source.manual_campaign_name as manual_campaign_name, 
    session_traffic_source_last_click.manual_campaign.source
    session_traffic_source_last_click.manual_campaign.medium
    session_traffic_source_last_click.manual_campaign.campaign_name
from 
    {{source('ga4_export','events_*')}}
WHERE 
    _TABLE_SUFFIX >= '20260701'

    
