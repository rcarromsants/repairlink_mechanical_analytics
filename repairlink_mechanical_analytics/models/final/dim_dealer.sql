{{ config(materialized='table') }}

with source as (
    select * from {{ ref('int_repairlink__dealer') }}
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['dealer_id']) }} as dealer_key,
        dealer_id,
        total_oem_count,
        active_oem_count,
        contact_type_id,
        org_name,
        first_name,
        last_name,
        email,
        phone_business,
        phone_mobile,
        address_line_1,
        address_line_2,
        city,
        state,
        postal_code,
        country_code
    from source
),

-- Unknown row for late-arriving facts (per Surrogate Key Strategy)
unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as dealer_key,
        'UNKNOWN'                as dealer_id,
        0                        as total_oem_count,
        0                        as active_oem_count,
        null::integer            as contact_type_id,
        'Unknown'                as org_name,
        null::varchar            as first_name,
        null::varchar            as last_name,
        null::varchar            as email,
        null::varchar            as phone_business,
        null::varchar            as phone_mobile,
        null::varchar            as address_line_1,
        null::varchar            as address_line_2,
        null::varchar            as city,
        null::varchar            as state,
        null::varchar            as postal_code,
        null::varchar            as country_code
)

select * from dimension
union all
select * from unknown_row
