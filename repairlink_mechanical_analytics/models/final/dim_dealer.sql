{{ config(materialized='table') }}

with dealers as (
    select * from {{ ref('int_repairlink__dealer') }}
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['dealer_id']) }} as dealer_key,
        dealer_trial_id,
        dealer_id,
        total_oem_enrollment_count,
        active_oem_enrollment_count,
        trial_started_at,
        trial_ended_at,
        created_at,
        updated_at,
        ingested_at
    from dealers
),

-- Unknown row for late-arriving facts (per Surrogate Key Strategy)
unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as dealer_key,
        null::integer            as dealer_trial_id,
        'UNKNOWN'                as dealer_id,
        0                        as total_oem_enrollment_count,
        0                        as active_oem_enrollment_count,
        null::timestamp_ntz      as trial_started_at,
        null::timestamp_ntz      as trial_ended_at,
        null::timestamp_ntz      as created_at,
        null::timestamp_ntz      as updated_at,
        null::timestamp_tz       as ingested_at
)

select * from dimension
union all
select * from unknown_row

-- Removed columns: status_id, connected_dealer_count - only 1 unique value in dev data
