{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_TRANSACTIONTYPE') }}

)

select
    transactiontypeid   as transaction_type_id,
    transactiontypekey  as transaction_type_name,
    transactiontypedtid as transaction_type_dt_id,
    frameworkclass      as framework_class,
    statusid            as status_id,
    sortorder           as sort_order,
    descriptiondtid     as description_dt_id,
    remark,
    _fivetran_deleted   as is_deleted,
    _fivetran_synced    as ingested_at
from source
where _fivetran_deleted = false