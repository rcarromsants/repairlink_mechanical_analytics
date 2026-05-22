{{ config(materialized='table') }}

with shops as (

    select *
    from {{ ref('stg_repairlink__shopconfig') }}

),

-- Latest shop configuration per shop_id
deduped_shops as (

    select *
    from shops
    qualify row_number() over (
        partition by shop_id
        order by updated_at desc
    ) = 1

),

-- Contact/org enrichment matched via canonical 11-char identifier
shop_contact_enrichment as (

    select
        left(org_key, 11) as shop_id,

        contact_type_id,
        contact_type_name,

        org_name,
        first_name,
        last_name,

        email,
        phone_business,
        phone_mobile,
        phone_fax,

        address_line_1,
        address_line_2,
        address_line_3,

        city,
        state,
        postal_code,
        country_code,

        latitude,
        longitude,

        locale_code,
        website,

        updated_at

    from {{ ref('int_repairlink__contact') }}

    where org_key is not null

    qualify row_number() over (
        partition by left(org_key, 11)
        order by updated_at desc nulls last
    ) = 1

),

final as (

    select

        s.shop_config_id,
        s.shop_id,

        s.location_code,
        s.order_type,

        -- Organizational/contact enrichment
        c.contact_type_id,
        c.contact_type_name,

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

        s.created_by,
        s.updated_by,

        s.created_at,
        s.updated_at,
        s.ingested_at

    from deduped_shops s
    left join shop_contact_enrichment c
        on left(s.shop_id, 11) = c.shop_id

)

select *
from final