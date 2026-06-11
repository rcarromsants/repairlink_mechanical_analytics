{{ config(materialized='table') }}

select
    -- identity
    part_pool_id,
    transaction_id,
    part_pool_type_id,

    -- part info
    part_no,
    part_description,
    manufacturer_id,
    part_type_external_id,
    part_type_internal_id,
    status_id,
    locale_code,

    -- part numbers by source (APM only — DLR / DMS / EPC 100% null in source)
    part_no_apm,

    -- part descriptions by source (APM + EPC only — DLR / DMS 100% null in source)
    part_description_apm,
    part_description_epc,

    -- APM pricing (all other source tiers 100% null in source)
    amt_unit_cost_apm,
    amt_unit_list_apm,
    amt_unit_wholesale_apm,
    amt_unit_trade_apm,
    amt_unit_core_apm,

    -- external integration
    external_xml,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from {{ ref('int_repairlink__partpool') }}
