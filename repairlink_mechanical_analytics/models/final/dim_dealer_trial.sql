{{ config(materialized='table') }}

-- One row per dealer trial record from DEALERTRIAL.
-- Keeps the latest lifecycle/business-status context for dealers with trial records.

with source as (

    select *
    from {{ ref('stg_repairlink__dealertrial') }}

),

deduped as (

    select *
    from source

    qualify row_number() over (
        partition by dealer_id
        order by updated_at desc nulls last
    ) = 1

)

select
    dealer_trial_id,
    dealer_id                                   as dealer_id_full,
    left(dealer_id, 11)                         as dealer_id,
    status_id,
    trial_started_at,
    trial_ended_at,
    (trial_ended_at is null)                    as is_active,
    created_at,
    updated_at,
    ingested_at

from deduped