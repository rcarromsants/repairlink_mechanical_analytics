{{ config(materialized='table') }}

-- Dealer universe = union of every distinct dealer_id referenced by any
-- dealer-specific source, normalized to the 11-char canonical form.
-- This anchors dim_dealer on the broader dealer ecosystem rather than the
-- tiny 18-row DEALERTRIAL subset.
with dealer_universe as (

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

-- OEM enrollment counts per dealer (total + currently active)
oem_counts as (

    select
        left(dealer_id, 11)                                       as dealer_id,
        count(distinct oem_id)                                    as total_oem_count,
        count(distinct case when is_active then oem_id end)       as active_oem_count
    from {{ ref('stg_repairlink__dealeroemenrollment') }}
    where dealer_id is not null
    group by 1

),

-- Pre-aggregate the int_contact enrichment to one row per dealer_id.
-- Within the same org_key there may be multiple contact_type_ids — we pick the
-- most recently updated contact row to attach as primary enrichment.
contact_enrichment as (

    select
        left(org_key, 11)        as dealer_id,
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
        country_code
    from {{ ref('int_repairlink__contact') }}
    where org_key is not null
    qualify row_number() over (
        partition by left(org_key, 11)
        order by updated_at desc nulls last
    ) = 1

),

final as (

    select
        d.dealer_id,

        -- OEM enrollment metrics
        coalesce(o.total_oem_count, 0)   as total_oem_count,
        coalesce(o.active_oem_count, 0)  as active_oem_count,

        -- Contact / organizational enrichment (nullable when no matching contact)
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
        c.country_code

    from dealer_universe d
    left join oem_counts        o using (dealer_id)
    left join contact_enrichment c using (dealer_id)

)

select * from final
