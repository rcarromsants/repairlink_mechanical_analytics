{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__currencymaster') }}
),

-- Exclude the sentinel 'Unknown' record (currency_id = 0)
final as (
    select *
    from source
    where currency_id != 0
)

select * from final
