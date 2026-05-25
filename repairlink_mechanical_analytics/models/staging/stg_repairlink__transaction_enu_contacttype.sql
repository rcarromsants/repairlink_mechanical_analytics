{{ config(materialized='view') }}

select
    contacttypeid  as contact_type_id,
    contacttypekey as contact_type_name,
    remark          as contact_type_remark
from {{ source('repairlink', 'TRANSACTION_ENU_CONTACTTYPE') }}