{{ config(
    schema = 'intermediate',
    materialized = 'table',
    tags = 'core'
) }}
-- ============================================================
-- MODEL: int_repairlink__suppliers
-- Purpose: Supplier dimension base with dealer/OEM mapping
-- Grain:   One row per supplier (seller org key)
-- Sources: stg_repairlink__contact (SOLD_BY) + stg_repairlink__dealer_mapper
--          + stg_repairlink__suppliermapper + int_repairlink__transactions
-- Used by: dim_repairlink_suppliers, dim_shop_supplier_connections
-- ============================================================

with supplier_transactions as (
    -- Aggregate transaction metrics per supplier
    select
        org_key_seller,
        min(trx_opened_at)  as first_transaction_date,
        max(trx_opened_at)  as last_transaction_date,
        count(*)            as total_transactions
    from {{ ref('int_repairlink__transactions') }}
    where transaction_state != 'VOID'
    group by org_key_seller
),

supplier_contacts as (
    -- Get latest contact info per supplier from transaction contacts
    -- contact_type_id = 101 means SOLD_BY (the seller/dealer)
    select
        c.org_key,
        left(c.org_key, 11) || '-000'   as supplier_parent_key,
        c.org_name,
        c.address_line_1,
        c.address_line_2,
        c.city,
        c.state,
        c.postal_code,
        c.country_code,
        c.latitude,
        c.longitude,
        c.phone_business,
        c.email
    from {{ ref('stg_repairlink__contact') }} as c
    inner join {{ ref('int_repairlink__transactions') }} as trx
        on c.transaction_id = trx.transaction_id
    where c.contact_type_id = 101
      and c.org_key is not null
    qualify row_number() over (
        partition by c.org_key
        order by c.updated_at desc nulls last
    ) = 1
)

select
    sc.org_key                          as supplier_org_key,
    -- Parent key normalizes branch-level org_key (e.g. 001-83S-CMT-014) to
    -- transaction-level org_key_seller (001-83S-CMT-000). All keys are 15 chars,
    -- format XXX-XXX-XXX-XXX. Suffix = dealer location; parent = dealer group.
    sc.supplier_parent_key,
    sc.org_name                         as supplier_name,
    sc.address_line_1,
    sc.address_line_2,
    sc.city,
    sc.state,
    sc.postal_code,
    sc.country_code                     as country,
    sc.latitude,
    sc.longitude,
    sc.phone_business                   as phone,
    sc.email,
    -- Dealer mapper provides group and distance info
    dm.dealer_id,
    dm.group_id,
    dm.distance_km,
    -- Supplier mapper provides supplier number
    sm.supplier_number,
    st.first_transaction_date,
    st.last_transaction_date,
    coalesce(st.total_transactions, 0)  as total_transactions
from supplier_contacts as sc
left join supplier_transactions as st
    on sc.supplier_parent_key = st.org_key_seller
left join {{ ref('stg_repairlink__dealer_mapper') }} as dm
    on sc.supplier_parent_key = dm.dealer_id
left join {{ ref('stg_repairlink__suppliermapper') }} as sm
    on sc.supplier_parent_key = sm.seller_org_key
