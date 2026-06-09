{{ config(materialized='table') }}

select
    -- identity
    line_item_id,
    line_item_no,
    line_item_parent_id,
    document_id,
    part_pool_id,
    line_item_type_id,
    line_item_sort,

    -- state
    line_item_state_id,
    line_item_substate_id,
    status_id,

    -- item info
    item_name,
    item_description,
    manufacturer_id,
    unit_of_measure_id,

    -- quantity
    qty,
    qty_available,
    qty_on_hand,
    qty_on_order,
    qty_each_per_unit,

    -- unit pricing
    amt_unit_cost,
    amt_unit_list,
    amt_unit_wholesale,
    amt_unit_trade,
    amt_unit_core,
    amt_unit_base,
    amt_unit_net,
    amt_unit_final,
    amt_unit_adjust,

    -- extended pricing (unit × qty)
    amt_ext_cost,
    amt_ext_list,
    amt_ext_wholesale,
    amt_ext_trade,
    amt_ext_core,
    amt_ext_base,
    amt_ext_net,
    amt_ext_final,
    amt_ext_adjust,

    -- tax & shipping
    amt_tax,
    amt_shipping,

    -- package / shipping
    package_type_id,
    package_weight,
    package_weight_uom_id,
    package_height,
    package_width,
    package_length,
    package_uom_id,
    package_ship_cost,
    package_est_value,
    package_tracking_no,

    -- sourcing
    part_pool_data_source,
    amt_baf_source,
    part_avail_at,

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
    line_item_event_log_id,
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from {{ ref('stg_repairlink__lineitem') }}
