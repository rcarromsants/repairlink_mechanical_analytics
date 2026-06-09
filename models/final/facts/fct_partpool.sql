{{ config(materialized='table') }}

select
    -- identity
    part_pool_id,
    transaction_id,
    part_pool_parent_id,
    part_pool_type_id,

    -- part info
    part_no,
    part_description,
    manufacturer_id,
    part_type_external_id,
    part_type_internal_id,
    status_id,
    locale_code,

    -- part numbers by source
    part_no_dlr,
    part_no_apm,
    part_no_dms,
    part_no_epc,

    -- part descriptions by source
    part_description_dlr,
    part_description_apm,
    part_description_dms,
    part_description_epc,

    -- part usage
    part_usage,
    part_usage_dlr,
    part_usage_apm,
    part_usage_dms,
    part_usage_epc,

    -- base unit pricing
    amt_unit_cost,
    amt_unit_list,
    amt_unit_wholesale,
    amt_unit_trade,
    amt_unit_core,

    -- dealer (DLR) pricing
    amt_unit_cost_dlr,
    amt_unit_list_dlr,
    amt_unit_wholesale_dlr,
    amt_unit_trade_dlr,
    amt_unit_core_dlr,

    -- APM pricing
    amt_unit_cost_apm,
    amt_unit_list_apm,
    amt_unit_wholesale_apm,
    amt_unit_trade_apm,
    amt_unit_core_apm,

    -- DMS pricing
    amt_unit_cost_dms,
    amt_unit_list_dms,
    amt_unit_wholesale_dms,
    amt_unit_trade_dms,
    amt_unit_core_dms,

    -- EPC pricing
    amt_unit_cost_epc,
    amt_unit_list_epc,
    amt_unit_wholesale_epc,
    amt_unit_trade_epc,
    amt_unit_core_epc,

    -- validation / scrubbing
    is_validate_pass,
    is_scrub_vin_pass,
    scrub_validated_at,
    scrub_validity_mask,

    -- external integration
    external_id,
    external_xml,
    external_ird,
    external_field_1,
    external_field_2,
    external_field_3,
    external_field_4,
    external_field_5,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from {{ ref('stg_repairlink__partpool') }}
