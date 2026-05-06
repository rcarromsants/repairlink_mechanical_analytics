{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__vehicle') }}
),

-- Deduplicate by VIN to get one row per physical vehicle (most recent transaction data).
-- Exclude records where VIN is null (~8% of rows) or vehicle_year = 0 (unknown/sentinel).
deduped as (
    select *
    from source
    where vin is not null
      and vehicle_year != 0
    qualify row_number() over (
        partition by vin
        order by updated_at desc nulls last
    ) = 1
)

select * from deduped
