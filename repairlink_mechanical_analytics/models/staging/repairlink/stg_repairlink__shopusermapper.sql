{{ config(materialized='incremental', unique_key='shop_user_mapper_id') }}

with source as (
    select * from {{ source('repairlink', 'SHOPUSERMAPPER') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(id             as integer)        as shop_user_mapper_id,
        cast(userid         as varchar)        as user_id,
        cast(externalid     as varchar)        as external_id,
        cast(createdby      as varchar)        as created_by,
        cast(updatedby      as varchar)        as updated_by,
        cast(createddate    as timestamp_ntz)  as created_at,
        cast(updateddate    as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced as timestamp_tz) as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
