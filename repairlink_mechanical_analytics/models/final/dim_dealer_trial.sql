{{ config(materialized='table') }}

-- One row per dealer trial record from DEALERTRIAL.
-- Keeps the lifecycle / business-status context for the small subset of
-- dealers that have a trial record (18 in current dev data).
-- Joins to dim_dealer via the 11-char canonical dealer_id (dealertrial stores
-- the 15-char form, so we strip the suffix to align).
with source as (
    select * from {{ ref('stg_repairlink__dealertrial') }}
),

deduped as (
    select *
    from source
    qualify row_number() over (
        partition by dealer_id
        order by updated_at desc nulls last
    ) = 1
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['dealer_trial_id']) }} as dealer_trial_key,
        dealer_trial_id,
        dealer_id                                                   as dealer_id_full,
        left(dealer_id, 11)                                         as dealer_id,
        status_id,
        trial_started_at,
        trial_ended_at,
        (trial_ended_at is null)                                    as is_active,
        created_at,
        updated_at,
        ingested_at
    from deduped
),

unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as dealer_trial_key,
        null::integer            as dealer_trial_id,
        'UNKNOWN'                as dealer_id_full,
        'UNKNOWN'                as dealer_id,
        null::integer            as status_id,
        null::timestamp_ntz      as trial_started_at,
        null::timestamp_ntz      as trial_ended_at,
        false                    as is_active,
        null::timestamp_ntz      as created_at,
        null::timestamp_ntz      as updated_at,
        null::timestamp_tz       as ingested_at
)

select * from dimension
union all
select * from unknown_row
