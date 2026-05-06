{{ config(materialized='incremental', unique_key='fivetran_id') }}

with source as (
    select * from {{ source('repairlink', 'DEALER_MAPPER') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        -- _fivetran_id used as PK because the source table has no natural primary key
        cast(_fivetran_id       as varchar)        as fivetran_id,
        cast(dealerid           as varchar)        as dealer_id,
        cast(connecteddealerid  as varchar)        as connected_dealer_id,
        cast(groupid            as integer)        as group_id,
        cast(distance_km        as float)          as distance_km,
        -- status = 3 for all current records; enum meaning not yet documented
        cast(status             as integer)        as status,
        cast(createdby          as varchar)        as created_by,
        cast(updatedby          as varchar)        as updated_by,
        cast(createdon          as timestamp_ntz)  as created_at,
        cast(updatedon          as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced   as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
