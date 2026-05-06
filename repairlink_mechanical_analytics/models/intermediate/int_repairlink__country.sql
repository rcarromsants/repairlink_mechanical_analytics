{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__countrymaster') }}
),

-- Exclude the sentinel 'Unknown' record (country_id = 0)
final as (
    select *
    from source
    where country_id != 0
)

select * from final
