{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_TRANSACTIONSUBSTATE') }}

)

select
    transactionsubstateid   as transaction_substate_id,
    transactionstateid      as transaction_state_id,
    transactionsubstatekey  as transaction_substate_name,
    transactionsubstatedtid as transaction_substate_dt_id,
    statusid                as status_id,
    sortorder               as sort_order,
    descriptiondtid         as description_dt_id,
    remark,
    _fivetran_deleted       as is_deleted,
    _fivetran_synced        as ingested_at
from source
where _fivetran_deleted = false