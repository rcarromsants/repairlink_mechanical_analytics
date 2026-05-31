{{ config(materialized='table') }}

-- Dealer universe built from:
-- 1. Operational dealer datasets
-- 2. Dealer-related organizational contacts (contact_type_id 101 / 104)
--
-- Contacts are now also treated as evidence of dealer existence,
-- not only downstream enrichment.
--
-- This logic should be revisited with the business in the future to confirm
-- whether contact-derived entities should permanently contribute to the
-- canonical dealer universe.

with operational_dealers as (

    select left(dealer_id, 11) as dealer_id
    from {{ ref('stg_repairlink__dealertrial') }}
    where dealer_id is not null

    union

    select dealer_id
    from {{ ref('stg_repairlink__dealer_mapper') }}
    where dealer_id is not null

    union

    select connected_dealer_id
    from {{ ref('stg_repairlink__dealer_mapper') }}
    where connected_dealer_id is not null

    union

    select left(dealer_id, 11)
    from {{ ref('stg_repairlink__dealeroemenrollment') }}
    where dealer_id is not null

),

-- Dealer entities inferred from organizational contacts
contact_dealers as (

    select distinct
        left(org_key, 11) as dealer_id

    from {{ ref('int_repairlink__contact') }}

    where org_key is not null
      and contact_type_id in (101, 104)

),

-- Full dealer universe
dealer_universe as (

    select
        coalesce(c.dealer_id, o.dealer_id) as dealer_id,

        case
            when c.dealer_id is not null then true
            else false
        end as is_contact_source,

        case
            when o.dealer_id is not null then true
            else false
        end as is_dealer_source

    from contact_dealers c

    full outer join operational_dealers o
        on c.dealer_id = o.dealer_id

),

-- OEM enrollment counts per dealer
oem_counts as (

    select
        left(dealer_id, 11)                                 as dealer_id,
        count(distinct oem_id)                              as total_oem_count,
        count(distinct case when is_active then oem_id end) as active_oem_count

    from {{ ref('stg_repairlink__dealeroemenrollment') }}

    where dealer_id is not null

    group by 1

),

-- Latest dealer-related contact enrichment
contact_enrichment as (

    select
        left(org_key, 11) as dealer_id,

        contact_type_id,

        org_name,
        first_name,
        last_name,
        email,

        phone_business,
        phone_mobile,

        address_line_1,
        address_line_2,

        city,
        state,
        postal_code,
        country_code,
        created_at,
        updated_at,
        ingested_at

    from {{ ref('int_repairlink__contact') }}

    where org_key is not null
      and contact_type_id in (101, 104)

    qualify row_number() over (
        partition by left(org_key, 11)
        order by updated_at desc nulls last
    ) = 1

),

final as (

    select
        d.dealer_id,

        d.is_contact_source,
        d.is_dealer_source,

        -- OEM metrics
        coalesce(o.total_oem_count, 0)  as total_oem_count,
        coalesce(o.active_oem_count, 0) as active_oem_count,

        -- Organizational enrichment
        c.contact_type_id,

        c.org_name,
        c.first_name,
        c.last_name,
        c.email,

        c.phone_business,
        c.phone_mobile,

        c.address_line_1,
        c.address_line_2,

        c.city,
        c.state,
        c.postal_code,
        c.country_code,
        c.created_at  as contact_created_at,
        c.updated_at  as contact_updated_at,
        c.ingested_at as contact_ingested_at

    from dealer_universe d

    left join oem_counts o
        using (dealer_id)

    left join contact_enrichment c
        using (dealer_id)

)

select *
from final