{{ config(materialized='table') }}

select
    map.id as page_id,
    p.page_path,
    p.page_title
from {{ ref('int_page_paths') }} p
left join {{ ref('page_id_map') }} map
    on {{ business_key_expr(['p.page_path', 'p.page_title']) }} = map.business_key
