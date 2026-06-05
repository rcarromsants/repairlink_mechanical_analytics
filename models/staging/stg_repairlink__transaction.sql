{{ config(materialized='incremental', unique_key='transaction_id') }}

with source as (
    select * from {{ source('repairlink', 'TRANSACTION_TRX_TRANSACTION') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        -- identity
        cast(transactionid              as integer)        as transaction_id,
        cast(transactionno              as varchar)        as transaction_no,
        cast(transactionparentid        as integer)        as transaction_parent_id,
        cast(workflowid                 as integer)        as workflow_id,

        -- type & state
        cast(transactiontypeid          as integer)        as transaction_type_id,
        cast(transactionsubtypeid       as integer)        as transaction_subtype_id,
        cast(transactionstateid         as integer)        as transaction_state_id,
        cast(transactionsubstateid      as integer)        as transaction_substate_id,
        cast(transmissiontypeid         as integer)        as transmission_type_id,
        cast(statusid                   as integer)        as status_id,

        -- parties (organisation keys)
        cast(orgkeybuyer                as varchar)        as org_key_buyer,
        cast(orgkeyseller               as varchar)        as org_key_seller,
        cast(orgkeyinitiator            as varchar)        as org_key_initiator,
        cast(orgkeyresponder            as varchar)        as org_key_responder,
        cast(orgkeyintegrator           as varchar)        as org_key_integrator,

        -- financials
        cast(amtparts                   as number(38,4))   as amt_parts,
        cast(amtlabor                   as number(38,4))   as amt_labor,
        cast(amtmaterials               as number(38,4))   as amt_materials,
        cast(amtsublet                  as number(38,4))   as amt_sublet,
        cast(amtdeductible              as number(38,4))   as amt_deductible,
        cast(amttrxsubtotal             as number(38,4))   as amt_trx_subtotal,
        cast(amttrxtax                  as number(38,4))   as amt_trx_tax,
        cast(amttrxshipping             as number(38,4))   as amt_trx_shipping,
        cast(amttrxadjustment           as number(38,4))   as amt_trx_adjustment,
        cast(amttrxtotal                as number(38,4))   as amt_trx_total,
        cast(currencyid                 as integer)        as currency_id,

        -- lifecycle dates
        cast(datetrxopen                as timestamp_ntz)  as trx_opened_at,
        cast(datetrxclose               as timestamp_ntz)  as trx_closed_at,
        cast(datetrxpost                as timestamp_ntz)  as trx_posted_at,
        cast(datetrxvoid                as timestamp_ntz)  as trx_voided_at,

        -- scheduling
        cast(timeappointment            as timestamp_ntz)  as appointment_at,
        cast(timecompleteestimate       as timestamp_ntz)  as complete_estimate_at,
        cast(timecompleteactual         as timestamp_ntz)  as complete_actual_at,
        cast(timecustomerpickup         as timestamp_ntz)  as customer_pickup_at,
        cast(timevehicledropoff         as timestamp_ntz)  as vehicle_dropoff_at,

        -- insurance / repair context
        cast(repairordernumber          as varchar)        as repair_order_number,
        cast(repairordertype            as varchar)        as repair_order_type,
        cast(claimnumber                as varchar)        as claim_number,
        cast(insurancecompanyname       as varchar)        as insurance_company_name,
        cast(externalinsuranceid        as varchar)        as external_insurance_id,
        cast(externalinsurancebranchid  as varchar)        as external_insurance_branch_id,
        cast(supplementlevel            as integer)        as supplement_level,

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
        cast(transactioneventlogid      as integer)        as transaction_event_log_id,
        cast(createdby                  as varchar)        as created_by,
        cast(updatedby                  as varchar)        as updated_by,
        cast(createdon                  as timestamp_ntz)  as created_at,
        cast(updatedon                  as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced           as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
