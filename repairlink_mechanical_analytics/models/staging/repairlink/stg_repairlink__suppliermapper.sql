{{ config(materialized='incremental', unique_key='supplier_mapper_id') }}

with source as (
    select * from {{ source('repairlink', 'SUPPLIERMAPPER') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(id                 as integer)        as supplier_mapper_id,
        cast(sellerorgkey       as varchar)        as seller_org_key,
        -- supplier_number is not unique; multiple seller_org_keys can map to the same supplier
        cast(suppliernumber     as integer)        as supplier_number,
        cast(_fivetran_synced   as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
