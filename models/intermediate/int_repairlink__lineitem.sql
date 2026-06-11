{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__lineitem') }}
)

select
    -- identity
    line_item_id,
    upper(trim(line_item_no))               as line_item_no,
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
    upper(trim(item_name))                  as item_name,
    upper(trim(item_description))           as item_description,
    manufacturer_id,
    unit_of_measure_id,

    -- quantity
    qty,
    qty_on_hand,
    qty_each_per_unit,

    -- unit pricing
    amt_unit_cost,
    amt_unit_list,
    amt_unit_wholesale,
    amt_unit_trade,
    amt_unit_core,
    amt_unit_net,
    amt_unit_final,

    -- extended pricing (unit × qty)
    amt_ext_net,
    amt_ext_final,

    -- sourcing
    upper(trim(part_pool_data_source))      as part_pool_data_source,
    part_avail_at,

    -- external integration
    upper(trim(external_id))                as external_id,
    trim(external_xml)                      as external_xml,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from source
