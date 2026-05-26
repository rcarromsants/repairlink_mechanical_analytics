{{ config(materialized='table') }}

with source as (

    select *
    from {{ ref('stg_repairlink__currencymaster') }}

),

final as (

    select
        currency_id,
        currency_code,
        currency_name,
        ingested_at
    from source
    where currency_id != 0

)

select *
from final