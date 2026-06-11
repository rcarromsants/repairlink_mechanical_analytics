{{ config(
    schema = 'intermediate',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    tags = 'core',
    unique_key = 'transaction_id',
    cluster_by = ['org_key_buyer', 'org_key_seller'],
    snowflake_warehouse = 'COLLISION_ANALYTICS_LARGE'
) }}
-- ============================================================
-- MODEL: int_repairlink__transactions
-- Purpose: Core transaction spine filtered to RepairLink products
-- Grain:   One row per transaction
-- Sources: stg_repairlink__transaction + 4 staging enum models
-- Filter:  transaction_subtype_id IN (105=RLK, 110=RLM)
-- Used by: All downstream models reference this as the base
-- ============================================================
select
    t.transaction_id,
    t.transaction_no,
    t.transaction_type_id,
    -- Decode transaction type: PURCHASE(100), SALE(200), CLAIM(300)
    tt.transaction_type_name as transaction_type,
    t.transaction_subtype_id,
    -- Decode subtype: REPAIR_LINK(105), REPAIR_LINK_MORE(110)
    tst.transaction_subtype_name as transaction_subtype,
    tst.transaction_subtype_code,
    t.transaction_state_id,
    -- Decode state: OPEN(100), CLOSED(200), VOID(300)
    ts.transaction_state_name as transaction_state,
    t.transaction_substate_id,
    -- Decode substate: NEW, SUBMITTED, RECEIVED, COMPLETED, CANCELED, etc.
    tss.transaction_substate_name as transaction_substate,
    -- Shop (buyer) and Supplier (seller) org keys
    t.org_key_buyer,
    t.org_key_seller,
    t.org_key_initiator,
    t.org_key_responder,
    t.repair_order_number,
    t.claim_number,
    -- Financial amounts at transaction level
    t.amt_parts,
    t.amt_labor,
    t.amt_materials,
    t.amt_sublet,
    t.amt_trx_subtotal,
    t.amt_trx_adjustment,
    t.amt_trx_shipping,
    t.amt_trx_tax,
    t.amt_trx_total,
    -- Transaction lifecycle dates
    t.trx_opened_at,
    t.trx_closed_at,
    t.trx_voided_at,
    t.trx_posted_at,
    t.created_at,
    t.updated_at
from {{ ref('stg_repairlink__transaction') }} as t
    left join {{ ref('stg_repairlink__transaction_type') }} as tt
        on t.transaction_type_id = tt.transaction_type_id
    left join {{ ref('stg_repairlink__transaction_subtype') }} as tst
        on t.transaction_subtype_id = tst.transaction_subtype_id
    left join {{ ref('stg_repairlink__transaction_state') }} as ts
        on t.transaction_state_id = ts.transaction_state_id
    left join {{ ref('stg_repairlink__transaction_substate') }} as tss
        on t.transaction_substate_id = tss.transaction_substate_id
-- Filter to RepairLink products only (105=classic RLK, 110=RLM current)
where t.transaction_subtype_id in (105, 110)

{% if is_incremental() %}
  and t.updated_at > (select max(updated_at) from {{ this }})
{% endif %}