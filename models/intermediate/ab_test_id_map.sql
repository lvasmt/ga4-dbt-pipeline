{{ config(materialized='incremental', incremental_strategy='merge', unique_key='business_key') }}

{{ generate_surrogate_id_map(
    source_relation=ref('int_ab_test_assignments'),
    business_key_columns=['test_name', 'variant']
) }}
