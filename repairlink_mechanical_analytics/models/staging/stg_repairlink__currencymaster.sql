{{ config(materialized='incremental', unique_key='currency_id') }}

with source as (
    select * from {{ source('repairlink', 'CURRENCYMASTER') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(currencyid             as integer)        as currency_id,
        cast(currency               as varchar)        as currency_name,
        cast(threeletterisocode     as varchar)        as currency_code,
        cast(_fivetran_synced       as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
