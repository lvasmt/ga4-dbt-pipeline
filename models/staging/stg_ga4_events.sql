select 
    event_date,
    event_timestamp,
    event_name,
    user_pseudo_id 
from 
    {{source('ga4_export','events_*')}}
WHERE 
    _TABLE_SUFFIX >= '20260701'