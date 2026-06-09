{{ config(materialized='table') }}

select
    -- identity
    transaction_id,
    transaction_no,
    transaction_parent_id,
    workflow_id,

    -- type & state
    transaction_type_id,
    transaction_subtype_id,
    transaction_state_id,
    transaction_substate_id,
    transmission_type_id,
    status_id,

    -- parties (organisation keys → join to dim_dealer / dim_shop)
    org_key_buyer,
    org_key_seller,
    org_key_initiator,
    org_key_responder,
    org_key_integrator,

    -- financials
    amt_parts,
    amt_labor,
    amt_materials,
    amt_sublet,
    amt_deductible,
    amt_trx_subtotal,
    amt_trx_tax,
    amt_trx_shipping,
    amt_trx_adjustment,
    amt_trx_total,
    currency_id,

    -- lifecycle dates
    trx_opened_at,
    trx_closed_at,
    trx_posted_at,
    trx_voided_at,

    -- scheduling
    appointment_at,
    complete_estimate_at,
    complete_actual_at,
    customer_pickup_at,
    vehicle_dropoff_at,

    -- insurance / repair context
    repair_order_number,
    repair_order_type,
    claim_number,
    insurance_company_name,
    external_insurance_id,
    external_insurance_branch_id,
    supplement_level,

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
    transaction_event_log_id,
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from {{ ref('stg_repairlink__transaction') }}
