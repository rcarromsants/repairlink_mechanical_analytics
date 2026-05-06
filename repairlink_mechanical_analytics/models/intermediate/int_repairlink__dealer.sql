{{ config(materialized='table') }}

with dealers as (
    select * from {{ ref('stg_repairlink__dealertrial') }}
),

oem_enrollments as (
    select
        dealer_id,
        count(*)                as total_oem_enrollment_count,
        count_if(is_active)     as active_oem_enrollment_count
    from {{ ref('stg_repairlink__dealeroemenrollment') }}
    group by dealer_id
),

-- Count how many other dealers each dealer is connected to via the distance network
dealer_connections as (
    select
        dealer_id,
        count(*) as connected_dealer_count
    from {{ ref('stg_repairlink__dealer_mapper') }}
    group by dealer_id
),

deduped as (
    select *
    from dealers
    qualify row_number() over (
        partition by dealer_id
        order by updated_at desc
    ) = 1
),

final as (
    select
        d.dealer_trial_id,
        d.dealer_id,
        d.status_id,
        d.trial_started_at,
        d.trial_ended_at,
        d.created_at,
        d.updated_at,
        d.ingested_at,
        coalesce(e.total_oem_enrollment_count, 0)   as total_oem_enrollment_count,
        coalesce(e.active_oem_enrollment_count, 0)  as active_oem_enrollment_count,
        coalesce(c.connected_dealer_count, 0)       as connected_dealer_count
    from deduped d
    left join oem_enrollments e  on d.dealer_id = e.dealer_id
    left join dealer_connections c on d.dealer_id = c.dealer_id
)

select * from final
