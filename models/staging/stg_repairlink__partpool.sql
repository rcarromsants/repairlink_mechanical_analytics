{{ config(materialized='incremental', unique_key='part_pool_id') }}

with source as (
    select * from {{ source('repairlink', 'TRANSACTION_TRX_PARTPOOL') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        -- identity
        cast(partpoolid                 as integer)        as part_pool_id,
        cast(transactionid              as integer)        as transaction_id,
        cast(partpoolparentid           as integer)        as part_pool_parent_id,
        cast(partpooltypeid             as integer)        as part_pool_type_id,

        -- part info
        cast(partno                     as varchar)        as part_no,
        cast(partdesc                   as varchar)        as part_description,
        cast(manufacturerid             as integer)        as manufacturer_id,
        cast(parttypeexternalid         as integer)        as part_type_external_id,
        cast(parttypeinternalid         as integer)        as part_type_internal_id,
        cast(statusid                   as integer)        as status_id,
        cast(localecode                 as varchar)        as locale_code,

        -- part numbers by source
        cast(partnodlr                  as varchar)        as part_no_dlr,
        cast(partnoapm                  as varchar)        as part_no_apm,
        cast(partnodms                  as varchar)        as part_no_dms,
        cast(partnoepc                  as varchar)        as part_no_epc,

        -- part descriptions by source
        cast(partdescdlr                as varchar)        as part_description_dlr,
        cast(partdescapm                as varchar)        as part_description_apm,
        cast(partdescdms                as varchar)        as part_description_dms,
        cast(partdescepc                as varchar)        as part_description_epc,

        -- part usage
        cast(partusage                  as number(38,4))   as part_usage,
        cast(partusagedlr               as number(38,4))   as part_usage_dlr,
        cast(partusageapm               as number(38,4))   as part_usage_apm,
        cast(partusagedms               as number(38,4))   as part_usage_dms,
        cast(partusageepc               as number(38,4))   as part_usage_epc,

        -- base unit pricing
        cast(amtunitcost                as number(38,4))   as amt_unit_cost,
        cast(amtunitlist                as number(38,4))   as amt_unit_list,
        cast(amtunitwholesale           as number(38,4))   as amt_unit_wholesale,
        cast(amtunittrade               as number(38,4))   as amt_unit_trade,
        cast(amtunitcore                as number(38,4))   as amt_unit_core,

        -- dealer (DLR) pricing
        cast(amtunitcostdlr             as number(38,4))   as amt_unit_cost_dlr,
        cast(amtunitlistdlr             as number(38,4))   as amt_unit_list_dlr,
        cast(amtunitwholesaledlr        as number(38,4))   as amt_unit_wholesale_dlr,
        cast(amtunittradedlr            as number(38,4))   as amt_unit_trade_dlr,
        cast(amtunitcoredlr             as number(38,4))   as amt_unit_core_dlr,

        -- APM pricing
        cast(amtunitcostapm             as number(38,4))   as amt_unit_cost_apm,
        cast(amtunitlistapm             as number(38,4))   as amt_unit_list_apm,
        cast(amtunitwholesaleapm        as number(38,4))   as amt_unit_wholesale_apm,
        cast(amtunittradeapm            as number(38,4))   as amt_unit_trade_apm,
        cast(amtunitcoreapm             as number(38,4))   as amt_unit_core_apm,

        -- DMS pricing
        cast(amtunitcostdms             as number(38,4))   as amt_unit_cost_dms,
        cast(amtunitlistdms             as number(38,4))   as amt_unit_list_dms,
        cast(amtunitwholesaledms        as number(38,4))   as amt_unit_wholesale_dms,
        cast(amtunittradedms            as number(38,4))   as amt_unit_trade_dms,
        cast(amtunitcoredms             as number(38,4))   as amt_unit_core_dms,

        -- EPC pricing
        cast(amtunitcostepc             as number(38,4))   as amt_unit_cost_epc,
        cast(amtunitlistepc             as number(38,4))   as amt_unit_list_epc,
        cast(amtunitwholesaleepc        as number(38,4))   as amt_unit_wholesale_epc,
        cast(amtunittradeepc            as number(38,4))   as amt_unit_trade_epc,
        cast(amtunitcoreepc             as number(38,4))   as amt_unit_core_epc,

        -- validation / scrubbing
        cast(validatepass               as boolean)        as is_validate_pass,
        cast(scrubvinpass               as boolean)        as is_scrub_vin_pass,
        cast(scrubvaldate               as timestamp_ntz)  as scrub_validated_at,
        cast(scrubvaliditymask          as integer)        as scrub_validity_mask,

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
        cast(createdby                  as varchar)        as created_by,
        cast(updatedby                  as varchar)        as updated_by,
        cast(createdon                  as timestamp_ntz)  as created_at,
        cast(updatedon                  as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced           as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
