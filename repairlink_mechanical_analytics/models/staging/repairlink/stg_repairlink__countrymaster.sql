{{ config(materialized='incremental', unique_key='country_id') }}

with source as (
    select * from {{ source('repairlink', 'COUNTRYMASTER') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(countryid              as integer)        as country_id,
        cast(country                as varchar)        as country_name,
        cast(twoletterisocode       as varchar)        as two_letter_iso_code,
        cast(threeletterisocode     as varchar)        as three_letter_iso_code,
        cast(_fivetran_synced       as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
