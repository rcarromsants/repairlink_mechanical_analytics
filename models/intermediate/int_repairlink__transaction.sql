{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__transaction') }}
)

select
    -- identity
    transaction_id,
    upper(trim(transaction_no))             as transaction_no,

    -- type & state
    transaction_type_id,
    transaction_subtype_id,
    transaction_state_id,
    transaction_substate_id,
    transmission_type_id,
    status_id,

    -- parties (organisation keys)
    upper(trim(org_key_buyer))              as org_key_buyer,
    upper(trim(org_key_seller))             as org_key_seller,
    upper(trim(org_key_initiator))          as org_key_initiator,
    upper(trim(org_key_responder))          as org_key_responder,
    upper(trim(org_key_integrator))         as org_key_integrator,

    -- financials
    amt_trx_subtotal,
    amt_trx_tax,
    amt_trx_total,
    currency_id,

    -- lifecycle dates
    trx_opened_at,

    -- repair context
    upper(trim(repair_order_number))        as repair_order_number,

    -- external integration
    upper(trim(external_id))                as external_id,
    trim(external_field_1)                  as external_field_1,
    trim(external_field_2)                  as external_field_2,
    trim(external_field_3)                  as external_field_3,
    trim(external_field_4)                  as external_field_4,
    trim(external_field_5)                  as external_field_5,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from source
