{{ config(materialized='incremental', unique_key='dealer_oem_enrollment_id') }}

with source as (
    select * from {{ source('repairlink', 'DEALEROEMENROLLMENT') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(id                 as integer)        as dealer_oem_enrollment_id,
        cast(dealerid           as varchar)        as dealer_id,
        cast(oemid              as integer)        as oem_id,
        -- oem_name is denormalized: same oem_id can appear with different names (e.g. id=1 → 'Chrysler' and 'DCX', id=3 → 'General Motors' and 'GM')
        cast(oemname            as varchar)        as oem_name,
        cast(isactive           as boolean)        as is_active,
        cast(createdonutc       as timestamp_ntz)  as created_at,
        cast(updatedonutc       as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced   as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
