{{ config(materialized='table') }}

-- Bridge table: many-to-many dealer ↔ OEM enrollment.
-- One row per enrollment record from DEALEROEMENROLLMENT.

with enrollments as (

    select *
    from {{ ref('stg_repairlink__dealeroemenrollment') }}

    where dealer_id is not null
      and oem_id    is not null

)

select
    dealer_oem_enrollment_id,

    left(dealer_id, 11) as dealer_id,
    dealer_id           as dealer_id_full,

    oem_id,
    oem_name,

    is_active,

    created_at as enrolled_at,
    updated_at,
    ingested_at

from enrollments