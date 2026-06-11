{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_DOCUMENTSUBTYPE') }}

)

select
    documentsubtypeid   as document_subtype_id,
    documenttypeid      as document_type_id,
    documentsubtypekey  as document_subtype_name,
    documentsubtypecode as document_subtype_code,
    documentsubtypedtid as document_subtype_dt_id,
    frameworkclass      as framework_class,
    statusid            as status_id,
    sortorder           as sort_order,
    descriptiondtid     as description_dt_id,
    remark,
    _fivetran_deleted   as is_deleted,
    _fivetran_synced    as ingested_at
from source
where _fivetran_deleted = false