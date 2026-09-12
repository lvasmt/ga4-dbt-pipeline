{% macro business_key_expr(columns) %}
{%- set expr -%}
concat({% for col in columns %}coalesce(cast({{ col }} as string), '(none)'){% if not loop.last %}, '||', {% endif %}{% endfor %})
{%- endset -%}
{{ return(expr) }}
{% endmacro %}
