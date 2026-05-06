{{ config(materialized='table') }}

with dealers as (
    select * from {{ ref('int_repairlink__dealer') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['dealer_id']) }} as dealer_key,
        dealer_id,
        status_id,
        trial_started_at,
        trial_ended_at,
        case
            when trial_ended_at is null then true
            else false
        end                                                   as is_active,
        created_at,
        updated_at
    from dealers
)

select * from final
