{% macro generate_surrogate_id_map(source_relation, business_key_columns) %}

{#
    Persisted, append-only key-mapping table: assigns a stable integer `id` to
    each distinct combination of business_key_columns, generated once and never
    reassigned on later runs (unlike a plain ROW_NUMBER() rebuild, which would
    shift ids every time the model is rebuilt). New business keys get the next
    available integer; existing ones are left untouched.

    Requires the calling model to be configured as:
        materialized='incremental', incremental_strategy='append'
#}

{%- set key_expr = business_key_expr(business_key_columns) -%}

with source_keys as (

    select distinct
        {% for col in business_key_columns -%}
        {{ col }},
        {% endfor -%}
        {{ key_expr }} as business_key
    from {{ source_relation }}

),

new_keys as (

    select *
    from source_keys
    {% if is_incremental() %}
    where business_key not in (select business_key from {{ this }})
    {% endif %}

)

select
    {% for col in business_key_columns -%}
    {{ col }},
    {% endfor -%}
    business_key,
    {% if is_incremental() -%}
    (select coalesce(max(id), 0) from {{ this }})
    {%- else -%}
    0
    {%- endif %} + row_number() over (order by business_key) as id
from new_keys

{% endmacro %}
