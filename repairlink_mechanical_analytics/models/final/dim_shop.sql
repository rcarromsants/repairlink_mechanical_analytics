{{ config(materialized='table') }}

with source as (
    select * from {{ ref('int_repairlink__shop') }}
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['shop_id']) }} as shop_key,
        shop_id,
        location_code,
        order_type,
        created_at,
        updated_at
    from source
),

-- Unknown row for late-arriving facts (per Surrogate Key Strategy)
unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as shop_key,
        'UNKNOWN'                as shop_id,
        null::varchar            as location_code,
        null::integer            as order_type,
        null::timestamp_ntz      as created_at,
        null::timestamp_ntz      as updated_at
)

select * from dimension
union all
select * from unknown_row

-- Removed columns: created_by, updated_by, ingested_at - no analytical value
