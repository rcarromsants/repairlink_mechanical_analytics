{{ config(materialized='table') }}

with source as (

    select distinct
        oem_id,
        oem_name
    from {{ ref('stg_repairlink__dealeroemenrollment') }}
    where oem_id is not null

),

normalized as (

    select
        oem_id,

        case
            when oem_id = 1 then 'Chrysler'
            when oem_id = 3 then 'General Motors'
            else oem_name
        end as oem_name

    from source

)

select distinct *
from normalized