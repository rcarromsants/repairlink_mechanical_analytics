{{ config(materialized='table') }}

select distinct
    contact_type_id,
    contact_type_name,
    contact_type_remark
from {{ ref('stg_repairlink__transaction_enu_contacttype') }}
where contact_type_id is not null