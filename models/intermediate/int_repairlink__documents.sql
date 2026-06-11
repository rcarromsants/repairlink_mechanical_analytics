{{ config(
    schema = 'intermediate',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    tags = 'core',
    unique_key = 'document_id',
    cluster_by = ['org_key_doc_source', 'org_key_doc_target'],
) }}
-- ============================================================
-- MODEL 2: int_repairlink_documents
-- Purpose: Documents (POs, Invoices, Shipments) with decoded types/states
-- Grain:   One row per document
-- Sources: stg_repairlink__document + 5 staging enum/lookup models
-- Joins:   INNER JOIN int_repairlink_transactions (scopes to RL only)
-- Used by: int_repairlink_line_items, fct_repairlink_orders
-- ============================================================
select
    d.document_id,
    d.transaction_id,
    d.document_no,
    d.document_type_id,
    -- Document type: PRELIMINARY(100), CONTRACTUAL(200), FINALIZED(300), MISC(400)
    dt.document_type_name as document_type,
    d.document_subtype_id,
    -- Document subtype: REQUEST_QUOTE, PURCHASE_ORDER, INVOICE, SHIPMENT, etc.
    dst.document_subtype_name as document_subtype,
    dst.document_subtype_code,
    d.document_state_id,
    -- Document state: OPEN(100), CLOSED(200), VOID(300)
    ds.document_state_name as document_state,
    d.document_substate_id,
    dss.document_substate_name as document_substate,
    -- Source = who created doc, Target = who receives it
    d.org_key_doc_source,
    d.org_key_doc_target,
    d.payment_method_id,
    -- Payment: COD, BILLEXISTINGACCOUNT, CREDITCARD, etc.
    pm.payment_method_name as payment_method,
    d.manufacturer_id,
    -- Financial amounts at document level
    d.amt_doc_subtotal,
    d.amt_doc_adjustment,
    d.amt_doc_shipping,
    d.amt_doc_handling,
    d.amt_doc_core_total,
    d.amt_doc_tax,
    d.amt_doc_total,
    -- Shipping info
    d.ship_at,
    d.ship_delivery_at,
    d.ship_tracking_no,
    -- Document lifecycle dates
    d.doc_opened_at,
    d.doc_closed_at,
    d.doc_voided_at,
    d.doc_posted_at,
    d.created_at,
    d.updated_at
from {{ ref('stg_repairlink__document') }} as d
-- INNER JOIN scopes documents to RepairLink transactions only
inner join {{ ref('int_repairlink__transactions') }} as trx
    on d.transaction_id = trx.transaction_id
left join {{ ref('stg_repairlink__document_type') }} as dt
    on d.document_type_id = dt.document_type_id
left join {{ ref('stg_repairlink__document_subtype') }} as dst
    on d.document_subtype_id = dst.document_subtype_id
left join {{ ref('stg_repairlink__document_state') }} as ds
    on d.document_state_id = ds.document_state_id
left join {{ ref('stg_repairlink__document_substate') }} as dss
    on d.document_substate_id = dss.document_substate_id
left join {{ ref('stg_repairlink__payment_method') }} as pm
    on d.payment_method_id = pm.payment_method_id

{% if is_incremental() %}
where d.updated_at > (select max(updated_at) from {{ this }})
{% endif %}