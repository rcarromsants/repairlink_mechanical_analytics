{{ config(materialized='table') }}

-- Distinct OEMs that dealers enroll with — sourced from DEALEROEMENROLLMENT.
-- oem_name is denormalised at source (same oem_id can appear with multiple name
-- variants, e.g. id=3 → 'General Motors' AND 'GM'). We pick the most frequent
-- spelling per oem_id as the canonical name.
with enrollments as (
    select
        oem_id,
        oem_name
    from {{ ref('stg_repairlink__dealeroemenrollment') }}
    where oem_id is not null
),

ranked_names as (
    select
        oem_id,
        oem_name,
        count(*) as occurrences
    from enrollments
    group by 1, 2
),

canonical as (
    select
        oem_id,
        oem_name
    from ranked_names
    qualify row_number() over (
        partition by oem_id
        order by occurrences desc, oem_name
    ) = 1
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['oem_id']) }} as oem_key,
        oem_id,
        oem_name
    from canonical
),

unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as oem_key,
        null::integer            as oem_id,
        'Unknown'                as oem_name
)

select * from dimension
union all
select * from unknown_row
