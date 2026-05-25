{{ config(materialized='table') }}

select
    country_id,
    country_name,
    two_letter_iso_code,
    three_letter_iso_code,
    ingested_at
from {{ ref('int_repairlink__country') }}