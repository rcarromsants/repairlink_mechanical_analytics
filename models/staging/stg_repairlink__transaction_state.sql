{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_TRANSACTIONSTATE') }}

)

select
    transactionstateid      as transaction_state_id,
    transactionstatekey     as transaction_state_name,
    transactionstatedtid    as transaction_state_dt_id,
    statusid                as status_id,
    sortorder               as sort_order,
    descriptiondtid         as description_dt_id,
    remark,
    _fivetran_deleted       as is_deleted,
    _fivetran_synced        as ingested_at
from source
where _fivetran_deleted = false