{{ config(materialized='incremental', unique_key='document_id') }}

with source as (
    select * from {{ source('repairlink', 'TRANSACTION_TRX_DOCUMENT') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        -- identity
        cast(documentid                 as integer)        as document_id,
        cast(documentno                 as varchar)        as document_no,
        cast(transactionid              as integer)        as transaction_id,
        cast(documentparentid           as integer)        as document_parent_id,

        -- type & state
        cast(documenttypeid             as integer)        as document_type_id,
        cast(documentsubtypeid          as integer)        as document_subtype_id,
        cast(documentstateid            as integer)        as document_state_id,
        cast(documentsubstateid         as integer)        as document_substate_id,
        cast(statusid                   as integer)        as status_id,

        -- parties (organisation keys)
        cast(orgkeydocsource            as varchar)        as org_key_doc_source,
        cast(orgkeydoctarget            as varchar)        as org_key_doc_target,

        -- sourcing
        cast(sourcingtype               as integer)        as sourcing_type,
        cast(manufacturerid             as integer)        as manufacturer_id,
        cast(paymentmethodid            as integer)        as payment_method_id,

        -- financials
        cast(amtdocsubtotal             as number(38,4))   as amt_doc_subtotal,
        cast(amtdoctax                  as number(38,4))   as amt_doc_tax,
        cast(amtdocshipping             as number(38,4))   as amt_doc_shipping,
        cast(amtdochandling             as number(38,4))   as amt_doc_handling,
        cast(amtdocadjustment           as number(38,4))   as amt_doc_adjustment,
        cast(amtdoccoretotal            as number(38,4))   as amt_doc_core_total,
        cast(amtdoctotal                as number(38,4))   as amt_doc_total,

        -- lifecycle dates
        cast(datedocopen                as timestamp_ntz)  as doc_opened_at,
        cast(datedocclose               as timestamp_ntz)  as doc_closed_at,
        cast(datedocpost                as timestamp_ntz)  as doc_posted_at,
        cast(datedocvoid                as timestamp_ntz)  as doc_voided_at,
        cast(daterequesteddelivery      as timestamp_ntz)  as requested_delivery_at,

        -- shipping
        cast(shipdate                   as timestamp_ntz)  as ship_at,
        cast(shipdeliverydate           as timestamp_ntz)  as ship_delivery_at,
        cast(shipexpecteddate           as timestamp_ntz)  as ship_expected_at,
        cast(shiptrackingno             as varchar)        as ship_tracking_no,
        cast(shipcarriertypeid          as integer)        as ship_carrier_type_id,
        cast(shipservicetypeid          as integer)        as ship_service_type_id,
        cast(shipbilltypeid             as integer)        as ship_bill_type_id,
        cast(shipdropofftypeid          as integer)        as ship_dropoff_type_id,
        cast(shipstrategytypeid         as integer)        as ship_strategy_type_id,
        cast(shipweight                 as number(38,4))   as ship_weight,
        cast(shipweightuomid            as integer)        as ship_weight_uom_id,
        cast(shipestvalue               as number(38,4))   as ship_est_value,
        cast(shipbillactshipper         as varchar)        as ship_bill_act_shipper,
        cast(shipbillactrecipient       as varchar)        as ship_bill_act_recipient,
        cast(shipbillactthirdparty      as varchar)        as ship_bill_act_third_party,

        -- external integration
        cast(externalid                 as varchar)        as external_id,
        cast(externalxml                as varchar)        as external_xml,
        cast(externalird                as varchar)        as external_ird,
        cast(externalfield1             as varchar)        as external_field_1,
        cast(externalfield2             as varchar)        as external_field_2,
        cast(externalfield3             as varchar)        as external_field_3,
        cast(externalfield4             as varchar)        as external_field_4,
        cast(externalfield5             as varchar)        as external_field_5,

        -- metadata
        cast(documenteventlogid         as integer)        as document_event_log_id,
        cast(createdby                  as varchar)        as created_by,
        cast(updatedby                  as varchar)        as updated_by,
        cast(createdon                  as timestamp_ntz)  as created_at,
        cast(updatedon                  as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced           as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
