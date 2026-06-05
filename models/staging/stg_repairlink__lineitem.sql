{{ config(materialized='incremental', unique_key='line_item_id') }}

with source as (
    select * from {{ source('repairlink', 'TRANSACTION_TRX_LINEITEM') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        -- identity
        cast(lineitemid                 as integer)        as line_item_id,
        cast(lineitemno                 as varchar)        as line_item_no,
        cast(lineitemparentid           as integer)        as line_item_parent_id,
        cast(documentid                 as integer)        as document_id,
        cast(partpoolid                 as integer)        as part_pool_id,
        cast(lineitemtypeid             as integer)        as line_item_type_id,
        cast(lineitemsort               as integer)        as line_item_sort,

        -- state
        cast(lineitemstateid            as integer)        as line_item_state_id,
        cast(lineitemsubstateid         as integer)        as line_item_substate_id,
        cast(statusid                   as integer)        as status_id,

        -- item info
        cast(itemname                   as varchar)        as item_name,
        cast(itemdesc                   as varchar)        as item_description,
        cast(manufacturerid             as integer)        as manufacturer_id,
        cast(unitofmeasureid            as integer)        as unit_of_measure_id,

        -- quantity
        cast(qty                        as number(38,4))   as qty,
        cast(qtyavailable               as number(38,4))   as qty_available,
        cast(qtyonhand                  as number(38,4))   as qty_on_hand,
        cast(qtyonorder                 as number(38,4))   as qty_on_order,
        cast(qtyeachperunit             as number(38,4))   as qty_each_per_unit,

        -- unit pricing
        cast(amtunitcost                as number(38,4))   as amt_unit_cost,
        cast(amtunitlist                as number(38,4))   as amt_unit_list,
        cast(amtunitwholesale           as number(38,4))   as amt_unit_wholesale,
        cast(amtunittrade               as number(38,4))   as amt_unit_trade,
        cast(amtunitcore                as number(38,4))   as amt_unit_core,
        cast(amtunitbase                as number(38,4))   as amt_unit_base,
        cast(amtunitnet                 as number(38,4))   as amt_unit_net,
        cast(amtunitfinal               as number(38,4))   as amt_unit_final,
        cast(amtunitadjust              as number(38,4))   as amt_unit_adjust,

        -- extended pricing (unit x quantity)
        cast(amtextcost                 as number(38,4))   as amt_ext_cost,
        cast(amtextlist                 as number(38,4))   as amt_ext_list,
        cast(amtextwholesale            as number(38,4))   as amt_ext_wholesale,
        cast(amtexttrade                as number(38,4))   as amt_ext_trade,
        cast(amtextcore                 as number(38,4))   as amt_ext_core,
        cast(amtextbase                 as number(38,4))   as amt_ext_base,
        cast(amtextnet                  as number(38,4))   as amt_ext_net,
        cast(amtextfinal                as number(38,4))   as amt_ext_final,
        cast(amtextadjust               as number(38,4))   as amt_ext_adjust,

        -- tax & shipping
        cast(amttax                     as number(38,4))   as amt_tax,
        cast(amtshipping                as number(38,4))   as amt_shipping,

        -- package / shipping
        cast(packagetypeid              as integer)        as package_type_id,
        cast(packageweight              as number(38,4))   as package_weight,
        cast(packagewgtuomid            as integer)        as package_weight_uom_id,
        cast(packageheight              as number(38,4))   as package_height,
        cast(packagewidth               as number(38,4))   as package_width,
        cast(packagelength              as number(38,4))   as package_length,
        cast(packageuomid               as integer)        as package_uom_id,
        cast(packageshipcost            as number(38,4))   as package_ship_cost,
        cast(packageestvalue            as number(38,4))   as package_est_value,
        cast(packagetrackingno          as varchar)        as package_tracking_no,

        -- sourcing
        cast(partpooldatasource         as varchar)        as part_pool_data_source,
        cast(amtbafsource               as number(38,4))   as amt_baf_source,
        cast(partavaildate              as timestamp_ntz)  as part_avail_at,

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
        cast(lineitemeventlogid         as integer)        as line_item_event_log_id,
        cast(createdby                  as varchar)        as created_by,
        cast(updatedby                  as varchar)        as updated_by,
        cast(createdon                  as timestamp_ntz)  as created_at,
        cast(updatedon                  as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced           as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
