{{ config(materialized='table') }}

with ab_tests as (

    select distinct
        test_name,
        variant
    from {{ ref('int_ab_test_assignments') }}

)

select
    map.id as ab_test_id,
    ab_tests.test_name,
    ab_tests.variant
from ab_tests
left join {{ ref('ab_test_id_map') }} as map
    on {{ business_key_expr(['ab_tests.test_name', 'ab_tests.variant']) }} = map.business_key
