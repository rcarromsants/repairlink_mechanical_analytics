{{ config(
    schema = 'intermediate',
    materialized = 'table',
    tags = 'core'
) }}
-- ============================================================
-- MODEL: int_repairlink__shop_activity
-- Purpose: Shop activity spine — enrolled universe with transaction KPIs
-- Grain:   One row per shop (buyer org key)
-- Sources: int_repairlink__shop (enrolled universe)
--          + transaction metrics from int_repairlink__transactions
--          + first document dates from stg_repairlink__document
-- KPIs:    Active Shop Rate(2), Inactive-Enrolled(6), base for all shop metrics
--
-- PLACEHOLDER: enrollment_date and days_to_first_transaction are NULL.
--   These require a CRM source (see PLACEHOLDER/FUTURE DATA section in docs).
--   When CRM data arrives, replace null::date with the actual enrollment date.
-- ============================================================

with shop_transactions as (
    -- Aggregate transaction metrics per shop from RL transactions
    select
        org_key_buyer,
        min(trx_opened_at)  as first_transaction_date,
        max(trx_opened_at)  as last_transaction_date,
        count(*)            as total_transactions
    from {{ ref('int_repairlink__transactions') }}
    where transaction_state != 'VOID'
    group by org_key_buyer
),

shop_first_estimates as (
    -- First WORKSHEET (estimate) per shop
    -- Worksheets are created when a shop begins building a parts request
    -- Filter: source != target to exclude self-referencing duplicates
    select
        trx.org_key_buyer           as shop_org_key,
        min(d.created_at::date)     as shop_first_estimate
    from {{ ref('stg_repairlink__document') }} as d
    inner join {{ ref('int_repairlink__transactions') }} as trx
        on d.transaction_id = trx.transaction_id
    where d.document_subtype_id = 404
      and d.document_state_id != 300
      and d.org_key_doc_source != d.org_key_doc_target
    group by trx.org_key_buyer
),

shop_first_orders as (
    -- First PURCHASE_ORDER per shop — the value moment
    select
        trx.org_key_buyer           as shop_org_key,
        min(d.created_at::date)     as shop_first_order
    from {{ ref('stg_repairlink__document') }} as d
    inner join {{ ref('int_repairlink__transactions') }} as trx
        on d.transaction_id = trx.transaction_id
    where d.document_subtype_id = 201
      and d.document_state_id != 300
    group by trx.org_key_buyer
)

select
    -- Use dim_shop as the enrolled universe
    -- shop_id || '-000' matches org_key_buyer format in transactions
    ds.shop_id || '-000'    as shop_org_key,
    ds.org_name             as shop_name,
    ds.address_line_1,
    ds.address_line_2,
    ds.city,
    ds.state,
    ds.postal_code,
    ds.country_code         as country,
    ds.latitude,
    ds.longitude,
    ds.phone_business       as phone,
    ds.email,
    -- PLACEHOLDER: enrollment_date requires CRM data
    -- Replace null with actual enrollment date when available
    null::date              as enrollment_date,
    sfe.shop_first_estimate,
    sfo.shop_first_order,
    st.first_transaction_date,
    st.last_transaction_date,
    coalesce(st.total_transactions, 0) as total_transactions,
    -- PLACEHOLDER: TTFT requires enrollment_date from CRM
    -- When available: datediff('day', enrollment_date, sfo.shop_first_order)
    null::number            as days_to_first_transaction
from {{ ref('dim_shop') }} as ds
-- Left joins preserve the full enrolled universe (including shops with 0 transactions)
left join shop_transactions as st
    on ds.shop_id || '-000' = st.org_key_buyer
left join shop_first_estimates as sfe
    on ds.shop_id || '-000' = sfe.shop_org_key
left join shop_first_orders as sfo
    on ds.shop_id || '-000' = sfo.shop_org_key
where ds.shop_id is not null