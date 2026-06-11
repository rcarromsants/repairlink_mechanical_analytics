{{ config(schema='staging', materialized='view', tags='stg_core') }}

with source as (

    select * from {{ source('repairlink', 'TRANSACTION_ENU_PAYMENTMETHOD') }}

)

select
    paymentmethodid     as payment_method_id,
    paymentmethodkey    as payment_method_name,
    paymentmethoddtid   as payment_method_dt_id,
    statusid            as status_id,
    sortorder           as sort_order,
    descriptiondtid     as description_dt_id,
    updatedon           as updated_at,
    remark,
    _fivetran_deleted   as is_deleted,
    _fivetran_synced    as ingested_at
from source
where _fivetran_deleted = false