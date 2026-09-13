{{ config(materialized='table') }}

select
    session_id_map.id as session_id,
    ab_test_id_map.id as ab_test_id
from {{ ref('int_ab_test_assignments') }} as assignments
left join {{ ref('session_id_map') }} as session_id_map
    on {{ business_key_expr(['assignments.session_code']) }} = session_id_map.business_key
left join {{ ref('ab_test_id_map') }} as ab_test_id_map
    on {{ business_key_expr(['assignments.test_name', 'assignments.variant']) }} = ab_test_id_map.business_key
