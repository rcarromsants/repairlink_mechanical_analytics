{{ config(materialized='table') }}

with source as (
    select * from {{ ref('int_repairlink__currency') }}
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['currency_id']) }} as currency_key,
        currency_id,
        currency_name,
        currency_code,
        ingested_at
    from source
),

-- Unknown row for late-arriving facts
unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as currency_key,
        null::integer            as currency_id,
        'Unknown'                as currency_name,
        'XXX'                    as currency_code,
        null::timestamp_tz       as ingested_at
)

select * from dimension
union all
select * from unknown_row

-- Note: currency_name is NOT unique (Kwacha = MWK + ZMK). Always join on currency_code, never currency_name.
