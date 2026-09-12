{{ config(materialized='incremental', incremental_strategy='merge', unique_key='business_key') }}

{{ generate_surrogate_id_map(
    source_relation=ref('int_page_paths'),
    business_key_columns=['page_path', 'page_title']
) }}
