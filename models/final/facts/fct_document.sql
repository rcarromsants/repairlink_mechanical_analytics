{{ config(materialized='table') }}

select
    -- identity
    document_id,
    document_no,
    transaction_id,
    document_parent_id,

    -- type & state
    document_type_id,
    document_subtype_id,
    document_state_id,
    document_substate_id,
    status_id,

    -- parties (organisation keys → join to dim_dealer / dim_shop)
    org_key_doc_source,
    org_key_doc_target,

    -- sourcing
    sourcing_type,
    manufacturer_id,
    payment_method_id,

    -- financials
    amt_doc_subtotal,
    amt_doc_tax,
    amt_doc_shipping,
    amt_doc_handling,
    amt_doc_adjustment,
    amt_doc_core_total,
    amt_doc_total,

    -- lifecycle dates
    doc_opened_at,
    doc_closed_at,
    doc_posted_at,
    doc_voided_at,
    requested_delivery_at,

    -- shipping
    ship_at,
    ship_delivery_at,
    ship_expected_at,
    ship_tracking_no,
    ship_carrier_type_id,
    ship_service_type_id,
    ship_bill_type_id,
    ship_dropoff_type_id,
    ship_strategy_type_id,
    ship_weight,
    ship_weight_uom_id,
    ship_est_value,
    ship_bill_act_shipper,
    ship_bill_act_recipient,
    ship_bill_act_third_party,

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
    document_event_log_id,
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from {{ ref('stg_repairlink__document') }}
