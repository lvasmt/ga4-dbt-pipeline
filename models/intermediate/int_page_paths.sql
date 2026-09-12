{{ config(materialized='view') }}

select distinct
    split(page_location, '?')[offset(0)] as page_path,
    page_title
from {{ ref('stg_ga4_events') }}
where page_location is not null
