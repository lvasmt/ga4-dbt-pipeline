{{ config(materialized='view') }}

-- Core reporting pipeline should only include consented hits. Excludes only
-- explicit denial ('No') -- null (no consent signal) is treated as included,
-- not as denial. Excluded rows aren't dropped anywhere -- stg_ga4_events stays
-- the full unfiltered raw layer, so this subset remains fully recoverable later
-- for modeling unconsented hits (parked, not built yet).

select *
from {{ ref('stg_ga4_events') }}
where consent_analytics_storage is distinct from 'No'
