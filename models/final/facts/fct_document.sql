{{ config(materialized='table') }}

select
    -- identity
    document_id,
    document_no,
    transaction_id,

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
    manufacturer_id,

    -- financials
    amt_doc_subtotal,
    amt_doc_tax,
    amt_doc_adjustment,
    amt_doc_core_total,
    amt_doc_total,

    -- lifecycle dates
    doc_opened_at,

    -- external integration
    external_id,
    external_xml,
    external_field_1,
    external_field_2,
    external_field_3,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from {{ ref('int_repairlink__document') }}
