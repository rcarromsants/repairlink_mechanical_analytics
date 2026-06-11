{{ config(materialized='table') }}

select
    -- identity
    transaction_id,
    transaction_no,

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
    amt_trx_subtotal,
    amt_trx_tax,
    amt_trx_total,
    currency_id,

    -- lifecycle dates
    trx_opened_at,

    -- repair context
    repair_order_number,

    -- external integration
    external_id,
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

from {{ ref('int_repairlink__transaction') }}
