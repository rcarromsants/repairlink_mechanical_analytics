{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_TRANSACTIONSUBTYPE') }}

)

select
    transactionsubtypeid        as transaction_subtype_id,
    transactiontypeid           as transaction_type_id,
    transactionsubtypekey       as transaction_subtype_name,
    transactionsubtypecode      as transaction_subtype_code,
    transactionsubtypedtid      as transaction_subtype_dt_id,
    frameworkclass              as framework_class,
    frameworkclassoverview      as framework_class_overview,
    statusid                    as status_id,
    sortorder                   as sort_order,
    descriptiondtid             as description_dt_id,
    remark,
    _fivetran_deleted           as is_deleted,
    _fivetran_synced            as ingested_at
from source
where _fivetran_deleted = false