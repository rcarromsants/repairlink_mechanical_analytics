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
    ) = 1 -- Keep the most recently updated record for each VIN, in case of duplicates - confirm with business if this is the desired behavior when there are duplicates
),

-- VIN intelligence reference dataset from Automotive Dimensions repository
vin_intelligence as (

    select *
    from {{ source('catalog_analytics', 'vintelligence_datafile') }}

), 

enriched as (

    select
        d.*,

        v.vin_signi_pattrn_mask as vin_vintelligence,

        -- to be removed later-it doesn't add any value—it was just for testing
        substring(trim(d.vin), 10, 2) as vin_suffix_vehicle, 
        substring(v.vin_signi_pattrn_mask, 10, 2) as vin_suffix_vintelligence,

        -- Original RepairLink values 
        -- Remove them once we have all the VIN records; there are many VINs with no matching records https://oeconnection.atlassian.net/browse/DAT-2341
        d.vehicle_make as vehicle_make_original,
        d.vehicle_model as vehicle_model_original,

        -- New VIN intelligence values
        v.mak_nm as vehicle_make_vintelligence,
        v.mdl_desc as vehicle_model_vintelligence

    from deduped d

    left join vin_intelligence v
        on left(trim(d.vin), 8) = left(v.vin_signi_pattrn_mask, 8)
       and substring(trim(d.vin), 10, 2)
            = substring(v.vin_signi_pattrn_mask, 10, 2)

)

select *
from enriched