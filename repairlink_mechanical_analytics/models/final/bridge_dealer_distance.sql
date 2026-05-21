{{ config(materialized='table') }}

-- Bridge table: many-to-many dealer ↔ dealer distance network.
-- One row per dealer pair from DEALER_MAPPER.
-- Both sides are already in the 11-char canonical form at source, so no
-- stripping is required.
with pairs as (
    select *
    from {{ ref('stg_repairlink__dealer_mapper') }}
    where dealer_id           is not null
      and connected_dealer_id is not null
),

bridge as (
    select
        -- Bridge surrogate keys aligned with dim_dealer (both ends)
        {{ dbt_utils.generate_surrogate_key(['dealer_id']) }}           as from_dealer_key,
        {{ dbt_utils.generate_surrogate_key(['connected_dealer_id']) }} as to_dealer_key,

        -- Source-side identifiers and metrics
        fivetran_id,
        dealer_id            as from_dealer_id,
        connected_dealer_id  as to_dealer_id,
        group_id,
        distance_km,
        status,
        created_at,
        updated_at,
        ingested_at
    from pairs
)

select * from bridge
