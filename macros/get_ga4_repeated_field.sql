{% macro get_ga4_repeated_field(field_name, param_name, value_type='string_value') %}
    (
        select kv.value.{{ value_type }}
        from unnest({{ field_name }}) as kv
        where kv.key = '{{ param_name }}'
    )
{% endmacro %}
