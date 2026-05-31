{{ config(materialized='table') }}

select
    shop_id,
    location_code,
    order_type,

    -- Organizational/contact enrichment
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
    is_contact_source,
    is_shop_source,
    contact_created_at,
    contact_updated_at,
    contact_ingested_at

from {{ ref('int_repairlink__shop') }}