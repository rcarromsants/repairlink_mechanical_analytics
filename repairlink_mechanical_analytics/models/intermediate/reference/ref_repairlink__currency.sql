{{ config(materialized='table') }}

select
    currency_id,
    currency_code,
    currency_name,
    ingested_at
from {{ ref('int_repairlink__currency') }}