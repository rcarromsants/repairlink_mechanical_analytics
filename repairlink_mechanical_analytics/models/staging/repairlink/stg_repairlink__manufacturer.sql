{{ config(materialized='incremental', unique_key='manufacturer_id') }}

with source as (
    select * from {{ source('repairlink', 'MASTER_ENT_MANUFACTURER') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(manufacturerid             as integer)        as manufacturer_id,
        cast(namelong                   as varchar)        as manufacturer_name_long,
        cast(nameshort                  as varchar)        as manufacturer_name_short,
        cast(abbreviation               as varchar)        as abbreviation,
        cast(manufacturerkey            as varchar)        as manufacturer_key,
        cast(orgkey                     as varchar)        as org_key,
        cast(industryid                 as integer)        as industry_id,
        cast(isphoenixpublishedinv      as boolean)        as is_phoenix_published_inv,
        cast(_fivetran_synced           as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
