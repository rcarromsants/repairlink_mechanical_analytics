{{ config(materialized='table') }}

with source as (

    select *
    from {{ ref('stg_repairlink__vehicle') }}

),

-- Deduplicate by VIN to get one row per physical vehicle
deduped as (

    select *
    from source
    where vin is not null

    qualify row_number() over (
        partition by vin
        order by updated_at desc nulls last
    ) = 1

),

-- VIN intelligence reference dataset
vin_intelligence as (

    select
        vin_signi_pattrn_mask,
        mak_nm,
        mdl_desc

    from {{ source('catalog_analytics', 'vintelligence_datafile') }}

    qualify row_number() over (
        partition by
            left(vin_signi_pattrn_mask, 8),
            substring(vin_signi_pattrn_mask, 10, 2)
        order by mak_nm nulls last
    ) = 1

),

enriched as (

    select
        d.vin,
        d.vehicle_id,
        d.transaction_id,
        d.vehicle_type_id,
        d.status_id,
        d.vehicle_year,

        -- Canonical make/model:
        -- Prefer Automotive Dimensions enrichment;
        -- fallback to normalized RepairLink values.

        coalesce(
            upper(ltrim(v.mak_nm)),
            upper(ltrim(d.vehicle_make))
        ) as vehicle_make,

        coalesce(
            upper(ltrim(v.mdl_desc)),
            upper(ltrim(d.vehicle_model))
        ) as vehicle_model,

        v.vin_signi_pattrn_mask as vin_vintelligence,

        case
            when v.mak_nm is not null then true
            else false
        end as vin_decoded_correctly,

        d.created_at,
        d.updated_at,
        d.ingested_at

    from deduped d

    left join vin_intelligence v
        on left(trim(d.vin), 8) = left(v.vin_signi_pattrn_mask, 8)
       and substring(trim(d.vin), 10, 2)
            = substring(v.vin_signi_pattrn_mask, 10, 2)

),

-- Defensive final dedup
final as (

    select *
    from enriched

    qualify row_number() over (
        partition by vin
        order by case when vin_decoded_correctly then 0 else 1 end
    ) = 1

)

select *
from final