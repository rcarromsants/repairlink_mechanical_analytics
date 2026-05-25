with source as (

    select *
    from {{ ref('stg_repairlink__shop') }}

),

contact_types as (

    select *
    from {{ ref('ref_repairlink__contact_type') }}

),

final as (

    select
        s.*,
        ct.contact_type_name

    from source s

    left join contact_types ct
        on s.contact_type_id = ct.contact_type_id

)

select * from final