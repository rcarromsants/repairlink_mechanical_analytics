{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__document') }}
)

select
    -- identity
    document_id,
    upper(trim(document_no))                as document_no,
    transaction_id,

    -- type & state
    document_type_id,
    document_subtype_id,
    document_state_id,
    document_substate_id,
    status_id,

    -- parties (organisation keys)
    upper(trim(org_key_doc_source))         as org_key_doc_source,
    upper(trim(org_key_doc_target))         as org_key_doc_target,

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
    upper(trim(external_id))                as external_id,
    trim(external_xml)                      as external_xml,
    upper(trim(external_field_1))           as external_field_1,
    upper(trim(external_field_2))           as external_field_2,
    upper(trim(external_field_3))           as external_field_3,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from source
