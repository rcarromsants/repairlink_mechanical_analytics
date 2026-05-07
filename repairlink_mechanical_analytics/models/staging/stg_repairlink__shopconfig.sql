{{ config(materialized='incremental', unique_key='shop_config_id') }}

with source as (
    select * from {{ source('repairlink', 'SHOPCONFIG') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(id             as integer)        as shop_config_id,
        cast(shopid         as varchar)        as shop_id,
        cast(locationcode   as varchar)        as location_code,
        cast(ordertype      as integer)        as order_type,
        cast(createdby      as varchar)        as created_by,
        cast(updatedby      as varchar)        as updated_by,
        cast(createddate    as timestamp_ntz)  as created_at,
        cast(updateddate    as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced as timestamp_tz) as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
