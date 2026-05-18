{{ config(materialized='table') }}

with source as (
    select * from {{ ref('int_repairlink__country') }}
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['country_id']) }} as country_key,
        country_id,
        country_name,
        two_letter_iso_code,
        three_letter_iso_code,
        ingested_at
    from source
),

-- Unknown row for late-arriving facts
unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as country_key,
        null::integer            as country_id,
        'Unknown'                as country_name,
        'XX'                     as two_letter_iso_code,
        'XXX'                    as three_letter_iso_code,
        null::timestamp_tz       as ingested_at
)

select * from dimension
union all
select * from unknown_row
