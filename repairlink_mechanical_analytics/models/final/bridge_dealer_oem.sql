{{ config(materialized='table') }}

-- Bridge table: many-to-many dealer ↔ OEM enrollment.
-- One row per enrollment record from DEALEROEMENROLLMENT.
-- Foreign keys are deterministic MD5 hashes — same dealer_id always produces
-- the same dealer_key, so this bridge stays joinable to dim_dealer and dim_oem
-- across full refreshes.
with enrollments as (
    select *
    from {{ ref('stg_repairlink__dealeroemenrollment') }}
    where dealer_id is not null
      and oem_id    is not null
),

bridge as (
    select
        -- Bridge surrogate keys aligned with the dims
        {{ dbt_utils.generate_surrogate_key(['left(dealer_id, 11)']) }} as dealer_key,
        {{ dbt_utils.generate_surrogate_key(['oem_id']) }}              as oem_key,

        -- Source-side identifiers and attributes
        dealer_oem_enrollment_id,
        left(dealer_id, 11)        as dealer_id,
        dealer_id                  as dealer_id_full,
        oem_id,
        oem_name,
        is_active,
        created_at                  as enrolled_at,
        updated_at,
        ingested_at
    from enrollments
)

select * from bridge
