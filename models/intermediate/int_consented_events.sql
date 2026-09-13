{{ config(materialized='view') }}

-- Core reporting pipeline should only include explicitly consented hits.
-- NULL is NOT treated as consented -- this property runs Advanced Consent
-- Mode, so null means "hasn't answered the consent banner yet" (pending),
-- not "no consent mechanism exists." Excluded rows aren't dropped anywhere --
-- stg_ga4_events stays the full unfiltered raw layer, so this subset remains
-- fully recoverable later for modeling unconsented/pending hits (parked, not
-- built yet).

select *
from {{ ref('stg_ga4_events') }}
where consent_analytics_storage = 'Yes'
