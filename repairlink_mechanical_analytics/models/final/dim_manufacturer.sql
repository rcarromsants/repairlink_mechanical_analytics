{{ config(materialized='table') }}

with source as (
    select * from {{ ref('int_repairlink__manufacturer') }}
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['manufacturer_id']) }} as manufacturer_key,
        manufacturer_id,
        manufacturer_name_long,
        manufacturer_name_short,
        abbreviation,
        manufacturer_key                                            as manufacturer_business_key,
        org_key,
        industry_id,
        is_phoenix_published_inv,
        ingested_at
    from source
),

-- Unknown row for late-arriving facts
unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as manufacturer_key,
        null::integer            as manufacturer_id,
        'Unknown'                as manufacturer_name_long,
        'Unknown'                as manufacturer_name_short,
        null::varchar            as abbreviation,
        'UNKNOWN'                as manufacturer_business_key,
        null::varchar            as org_key,
        null::integer            as industry_id,
        null::boolean            as is_phoenix_published_inv,
        null::timestamp_tz       as ingested_at
)

select * from dimension
union all
select * from unknown_row
