{{ config(materialized='incremental', unique_key='line_item_id') }}

with source as (
    select * from {{ source('repairlink', 'PMAPROGRAM_XRF_LINEITEM') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        -- identity
        -- line_item_id is the source PK (one PMA row per line item) and an OPTIONAL
        -- relationship to fct_lineitem — ~73% of these reference line items no longer
        -- present in TRANSACTION_TRX_LINEITEM, so downstream joins must be LEFT joins.
        cast(lineitemid              as integer)        as line_item_id,
        cast(programid               as integer)        as program_id,
        cast(transactionid           as integer)        as transaction_id,

        -- classification
        cast(comparisonresultid      as integer)        as comparison_result_id,
        cast(qualificationtypeid     as integer)        as qualification_type_id,
        cast(qualificationstatusid   as integer)        as qualification_status_id,
        cast(statusid                as integer)        as status_id,

        -- program detail
        cast(programvalue            as number(38,4))   as program_value,
        cast(programmatchmessage     as varchar)        as program_match_message,
        cast(programdisplaytext      as varchar)        as program_display_text,
        cast(partnumoexref           as varchar)        as part_num_oe_xref,
        cast(showcolumns             as boolean)        as is_show_columns,

        -- metadata
        cast(createdby               as varchar)        as created_by,
        cast(updatedby               as varchar)        as updated_by,
        cast(createdon               as timestamp_ntz)  as created_at,
        cast(updatedon               as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced        as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
