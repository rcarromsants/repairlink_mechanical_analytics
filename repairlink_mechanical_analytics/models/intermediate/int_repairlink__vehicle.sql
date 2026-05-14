{{ config(materialized='table') }}

with source as (

    select *
    from {{ ref('stg_repairlink__vehicle') }}

),

-- Deduplicate by VIN to get one row per physical vehicle.
deduped as (

    select *
    from source
    where vin is not null
      and vehicle_year != 0

    qualify row_number() over (
        partition by vin
        order by updated_at desc nulls last
    ) = 1

),

vin_intelligence as (

    select *
    from {{ source('catalog_analytics', 'vintelligence_datafile') }}

),

enriched as (

    select

        -- Original vehicle fields
        d.*,

        v.vin_signi_pattrn_mask as vin_vintelligence,

        substring(trim(d.vin), 10, 2) as vin_suffix_vehicle,
        substring(v.vin_signi_pattrn_mask, 10, 2) as vin_suffix_vintelligence,

        -- Original RepairLink values
        d.vehicle_make as vehicle_make_original,
        d.vehicle_model as vehicle_model_original,

        -- New VIN intelligence values
        v.mak_nm as vehicle_make_vintelligence,
        v.mdl_desc as vehicle_model_vintelligence,

        -- Optional debugging / lineage
        v.vin_signi_pattrn_mask,
        v.mdl_yr

    from deduped d

    left join vin_intelligence v
        on left(trim(d.vin), 8) = left(v.vin_signi_pattrn_mask, 8)
       and substring(trim(d.vin), 10, 2)
            = substring(v.vin_signi_pattrn_mask, 10, 2)

)

select *
from enriched