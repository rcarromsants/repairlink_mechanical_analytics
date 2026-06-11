{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_DOCUMENTTYPE') }}

)

select
    documenttypeid      as document_type_id,
    documenttypekey     as document_type_name,
    documenttypedtid    as document_type_dt_id,
    frameworkclass      as framework_class,
    statusid            as status_id,
    sortorder           as sort_order,
    descriptiondtid     as description_dt_id,
    remark,
    _fivetran_deleted   as is_deleted,
    _fivetran_synced    as ingested_at
from source
where _fivetran_deleted = false