{{ config(materialized='table') }}

select
    dealer_id,
    total_oem_count,
    active_oem_count,
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
    is_contact_source,
    is_dealer_source,
    contact_created_at,
    contact_updated_at,
    contact_ingested_at
from {{ ref('int_repairlink__dealer') }}