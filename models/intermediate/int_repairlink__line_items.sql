{{ config(
    schema = 'intermediate',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    tags = 'core',
    unique_key = 'line_item_id',
    cluster_by = ['document_id', 'line_item_type_id'],
    snowflake_warehouse = 'COLLISION_ANALYTICS_LARGE'
) }}
-- ============================================================
-- MODEL: int_repairlink__line_items
-- Purpose: Part-level detail with pricing from part pool
-- Grain:   One row per line item (part/service/labor)
-- Sources: stg_repairlink__lineitem + stg_repairlink__partpool + 4 staging enum models
-- Joins:   INNER JOIN int_repairlink__documents (scopes to RL docs)
-- Used by: fct_repairlink_orders
-- ============================================================
select
    li.line_item_id,
    li.document_id,
    -- Carry transaction_id through for downstream joins
    doc.transaction_id,
    li.line_item_parent_id,
    li.line_item_type_id,
    -- Line item type: SERVICE(100), LABOR(101), PART(102), MATERIAL(103), BUNDLE(104), PACKAGE(200)
    lit.line_item_type_name as line_item_type,
    li.line_item_state_id,
    -- Line item state: OPEN(100), CLOSED(200), VOID(300)
    lis.line_item_state_name as line_item_state,
    li.line_item_substate_id,
    -- Substate: SHIPPED, INVOICED, QUOTED, NOT_AVAILABLE, BACKORDERED, etc.
    liss.line_item_substate_name as line_item_substate,
    li.item_name,
    li.item_description,
    li.line_item_no,
    -- Part pool data (the actual part details)
    li.part_pool_id,
    pp.part_no,
    pp.part_description,
    pp.manufacturer_id,
    pp.part_pool_type_id,
    -- Part pool type: REQUESTED(100), ALTERNATE(101), EQUIVALENT(102), RELATED(103)
    ppt.part_pool_type_name as part_pool_type,
    -- Quantities
    li.qty,
    li.qty_available,
    li.qty_on_hand,
    li.qty_on_order,
    -- Unit pricing (per single item)
    li.amt_unit_list,
    li.amt_unit_cost,
    li.amt_unit_net,
    li.amt_unit_final,
    li.amt_unit_adjust,
    li.amt_unit_core,
    -- Extended pricing (unit * qty)
    li.amt_ext_final,
    li.amt_ext_list,
    li.amt_ext_cost,
    li.amt_ext_net,
    li.amt_ext_adjust,
    li.amt_ext_core,
    li.amt_tax,
    li.amt_shipping,
    li.part_avail_at,
    li.created_at,
    li.updated_at
from {{ ref('stg_repairlink__lineitem') }} as li
-- INNER JOIN scopes line items to RL documents only
inner join {{ ref('int_repairlink__documents') }} as doc
    on li.document_id = doc.document_id
-- Part pool provides the actual part number, description, manufacturer
left join {{ ref('stg_repairlink__partpool') }} as pp
    on li.part_pool_id = pp.part_pool_id
left join {{ ref('stg_repairlink__lineitem_type') }} as lit
    on li.line_item_type_id = lit.line_item_type_id
left join {{ ref('stg_repairlink__lineitem_state') }} as lis
    on li.line_item_state_id = lis.line_item_state_id
-- Substate requires both substate ID and parent state ID for correct lookup
left join {{ ref('stg_repairlink__lineitem_substate') }} as liss
    on li.line_item_substate_id = liss.line_item_substate_id
    and li.line_item_state_id = liss.line_item_state_id
left join {{ ref('stg_repairlink__partpool_type') }} as ppt
    on pp.part_pool_type_id = ppt.part_pool_type_id

{% if is_incremental() %}
where li.updated_at > (select max(updated_at) from {{ this }})
{% endif %}