{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__manufacturer') }}
),

-- Exclude the sentinel 'Unknown' record (manufacturer_id = 0)
final as (
    select *
    from source
    where manufacturer_id != 0
)

select * from final
