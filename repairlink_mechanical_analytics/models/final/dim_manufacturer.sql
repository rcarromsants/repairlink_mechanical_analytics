{{ config(materialized='table') }}

select
    manufacturer_id,
    manufacturer_name_long,
    manufacturer_name_short,
    abbreviation,
    manufacturer_key as manufacturer_business_key,
    org_key,
    industry_id,
    is_phoenix_published_inv,
    ingested_at
from {{ ref('int_repairlink__manufacturer') }}