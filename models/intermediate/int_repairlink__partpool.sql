{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__partpool') }}
)

select
    -- identity
    part_pool_id,
    transaction_id,
    part_pool_type_id,

    -- part info
    upper(trim(part_no))                    as part_no,
    upper(trim(part_description))           as part_description,
    manufacturer_id,
    part_type_external_id,
    part_type_internal_id,
    status_id,
    upper(trim(locale_code))                as locale_code,

    -- part numbers by source (APM only — DLR / DMS / EPC 100% null)
    upper(trim(part_no_apm))                as part_no_apm,

    -- part descriptions by source (APM + EPC only — DLR / DMS 100% null)
    upper(trim(part_description_apm))       as part_description_apm,
    upper(trim(part_description_epc))       as part_description_epc,

    -- APM pricing (all other source tiers 100% null)
    amt_unit_cost_apm,
    amt_unit_list_apm,
    amt_unit_wholesale_apm,
    amt_unit_trade_apm,
    amt_unit_core_apm,

    -- external integration
    trim(external_xml)                      as external_xml,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from source
