{{ config(materialized='table') }}

with device as (

    select
        device_category,
        device_brand,
        device_model,
        min(device_marketing_name) as device_marketing_name -- assumed deterministic per (category, brand, model); not part of the business key
    from {{ ref('int_sessions') }}
    group by
        device_category,
        device_brand,
        device_model

)

select
    map.id as device_id,
    device.device_category,
    device.device_brand,
    device.device_model,
    device.device_marketing_name
from device
left join {{ ref('device_id_map') }} as map
    on {{ business_key_expr(['device.device_category', 'device.device_brand', 'device.device_model']) }} = map.business_key
