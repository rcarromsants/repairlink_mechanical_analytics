{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_DOCUMENTSUBSTATE') }}

)

select
    documentsubstateid  as document_substate_id,
    documentstateid     as document_state_id,
    documentsubstatekey as document_substate_name,
    documentsubstatedtid as document_substate_dt_id,
    statusid            as status_id,
    sortorder           as sort_order,
    descriptiondtid     as description_dt_id,
    remark,
    _fivetran_deleted   as is_deleted,
    _fivetran_synced    as ingested_at
from source
where _fivetran_deleted = false