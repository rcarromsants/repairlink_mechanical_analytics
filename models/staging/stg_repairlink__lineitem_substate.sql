{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_LINEITEMSUBSTATE') }}

)

select
    lineitemsubstateid  as line_item_substate_id,
    lineitemstateid     as line_item_state_id,
    lineitemsubstatekey as line_item_substate_name,
    lineitemsubstatedtid as line_item_substate_dt_id,
    statusid            as status_id,
    sortorder           as sort_order,
    descriptiondtid     as description_dt_id,
    remark,
    _fivetran_deleted   as is_deleted,
    _fivetran_synced    as ingested_at
from source
where _fivetran_deleted = false