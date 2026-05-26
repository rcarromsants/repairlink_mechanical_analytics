{{ config(materialized='table') }}

with source as (

    select *
    from {{ ref('stg_repairlink__countrymaster') }}

),

final as (

    select
        country_id,
        country_name,
        two_letter_iso_code,
        three_letter_iso_code,
        ingested_at
    from source
    where country_id != 0

)

select *
from final