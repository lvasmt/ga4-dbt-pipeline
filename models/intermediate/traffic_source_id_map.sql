{{ config(materialized='incremental', incremental_strategy='merge', unique_key='business_key') }}

{{ generate_surrogate_id_map(
    source_relation=ref('int_sessions'),
    business_key_columns=['session_source', 'session_medium', 'session_campaign_name']
) }}
