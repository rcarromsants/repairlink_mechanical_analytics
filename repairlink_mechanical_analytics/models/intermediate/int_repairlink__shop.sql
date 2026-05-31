{{ config(materialized='table') }}

-- Shop universe built from:
-- 1. Operational shop configuration data
-- 2. Shop-related organizational contacts (contact_type_id 100 / 103)
--
-- Contacts are now also treated as evidence of shop existence,
-- not only downstream enrichment.
--
-- This logic should be revisited with the business in the future to confirm
-- whether contact-derived entities should permanently contribute to the
-- canonical shop universe.

with operational_shops as (

    select
        shop_id,
        location_code,
        order_type

    from {{ ref('stg_repairlink__shopconfig') }}

    where shop_id is not null

),

-- Shop entities inferred from organizational contacts
contact_shops as (

    select distinct
        left(org_key, 11) as shop_id

    from {{ ref('int_repairlink__contact') }}

    where org_key is not null
      and contact_type_id in (100, 103)

),

-- Full shop universe
shop_universe as (

    select
        coalesce(c.shop_id, o.shop_id) as shop_id,

        o.location_code,
        o.order_type,

        case
            when c.shop_id is not null then true
            else false
        end as is_contact_source,

        case
            when o.shop_id is not null then true
            else false
        end as is_shop_source

    from contact_shops c

    full outer join operational_shops o
        on c.shop_id = o.shop_id

),

contact_types as (

    select *
    from {{ ref('ref_repairlink__contact_type') }}

),

-- Latest shop-related contact enrichment
contact_enrichment as (

    select
        left(org_key, 11) as shop_id,

        contact_type_id,

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

        created_at,
        updated_at,
        ingested_at

    from {{ ref('int_repairlink__contact') }}

    where org_key is not null
      and contact_type_id in (100, 103)

    qualify row_number() over (
        partition by left(org_key, 11)
        order by updated_at desc nulls last
    ) = 1

),

final as (

    select
        s.shop_id,

        s.location_code,
        s.order_type,

        s.is_contact_source,
        s.is_shop_source,

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

        c.created_at  as contact_created_at,
        c.updated_at  as contact_updated_at,
        c.ingested_at as contact_ingested_at

    from shop_universe s

    left join contact_enrichment c
        using (shop_id)

    left join contact_types ct
        on c.contact_type_id = ct.contact_type_id

)

select *
from final