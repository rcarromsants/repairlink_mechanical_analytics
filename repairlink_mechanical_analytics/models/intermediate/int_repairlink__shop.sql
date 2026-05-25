{{ config(materialized='table') }}

with source as (

    select *
    from {{ ref('stg_repairlink__shopconfig') }}

),

contact_types as (

    select *
    from {{ ref('ref_repairlink__contact_type') }}

),

contacts as (

    select *
    from {{ ref('int_repairlink__contact') }}

),

final as (

    select
        s.shop_id,
        s.location_code,
        s.order_type,

        c.contact_type_id,
        ct.contact_type_name,
        ct.contact_type_remark,

        c.org_name,
        c.first_name,
        c.last_name,
        c.email,

        c.phone_business,
        c.phone_mobile,
        c.phone_fax,

        c.address_line_1,
        c.address_line_2,
        c.address_line_3,

        c.city,
        c.state,
        c.postal_code,
        c.country_code,

        c.latitude,
        c.longitude,

        c.locale_code,
        c.website,

        c.created_at,
        c.updated_at

    from source s

    left join contacts c
        on s.shop_id = left(c.org_key, 11)

    left join contact_types ct
        on c.contact_type_id = ct.contact_type_id

)

select *
from final