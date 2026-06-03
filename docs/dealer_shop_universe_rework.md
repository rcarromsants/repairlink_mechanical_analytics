# Dealer & Shop Universe Rework Notes

## Context

A data quality validation performed between `int_repairlink__contact`
and the current dealer/shop entities identified additional operational
entities present in the contact dataset but not currently represented
in `int_repairlink__dealer` and `int_repairlink__shop`.

Dealer-related contacts:
- `contact_type_id IN (101, 104)`

Shop-related contacts:
- `contact_type_id IN (100, 103)`

As a result, the entity modeling logic was updated so that organizational
contacts can also contribute to entity identification and coverage.

This implementation reflects the current operational interpretation of
the available data and should be revisited with the business in the future.

---

# Previous logic — int_repairlink__dealer

## Previous universe definition

The dealer universe was built exclusively from operational datasets:

- `stg_repairlink__dealertrial`
- `stg_repairlink__dealer_mapper`
- `stg_repairlink__dealeroemenrollment`

Organizational contacts were used only for downstream enrichment.

## Previous SQL logic

```
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
```

---

# Current logic — int_repairlink__dealer

## Current universe definition

The dealer universe now combines:

- operational dealer datasets;
- dealer-related organizational contacts.

Dealer-related contacts are identified using:

```sql
contact_type_id IN (101, 104)
```

The model also exposes:

- `is_contact_observed`
- `is_operationally_observed`

to support coverage analysis and future business validation.

---

# Previous logic — int_repairlink__shop

## Previous universe definition

The shop universe was built exclusively from:

- `stg_repairlink__shopconfig`

Organizational contacts were used only for enrichment.

## Previous SQL logic

```
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

```

---

# Current logic — int_repairlink__shop

## Current universe definition

The shop universe now combines:

- operational shop configuration records;
- shop-related organizational contacts.

Shop-related contacts are identified using:

```sql
contact_type_id IN (100, 103)
```

The model also exposes:

- `is_contact_observed`
- `is_operationally_observed`

to support coverage analysis and future business validation.

---

# Important note

This rework introduces a conceptual change where organizational contacts
are treated as evidence of entity existence rather than only enrichment.

If future business validation determines this assumption is incorrect,
the models can be reverted using the previous logic preserved in this document.