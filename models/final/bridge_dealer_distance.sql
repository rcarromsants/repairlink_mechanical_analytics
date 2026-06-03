{{ config(materialized='table') }}

-- Bridge table: many-to-many dealer ↔ dealer distance network.
-- One row per dealer pair from DEALER_MAPPER.

with pairs as (

    select *
    from {{ ref('stg_repairlink__dealer_mapper') }}

    where dealer_id           is not null
      and connected_dealer_id is not null

)

select
    fivetran_id,

    dealer_id           as from_dealer_id,
    connected_dealer_id as to_dealer_id,

    group_id,
    distance_km,
    status,
    created_at,
    updated_at,
    ingested_at

from pairs