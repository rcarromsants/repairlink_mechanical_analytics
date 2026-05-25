{{ config(materialized='table') }}

select distinct
    oem_id,
    oem_name
from {{ ref('stg_repairlink__dealeroemenrollment') }}
where oem_id is not null