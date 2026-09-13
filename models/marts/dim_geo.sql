{{ config(materialized='table') }}

with geo as (

    select distinct
        country,
        city
    from {{ ref('int_sessions') }}

)

select
    map.id as geo_id,
    geo.country,
    geo.city
from geo
left join {{ ref('geo_id_map') }} as map
    on {{ business_key_expr(['geo.country', 'geo.city']) }} = map.business_key
