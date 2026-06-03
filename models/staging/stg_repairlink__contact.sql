{{ config(materialized='incremental', unique_key='contact_id') }}

with source as (
    select * from {{ source('repairlink', 'TRANSACTION_ENT_CONTACT') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(contactid          as integer)        as contact_id,
        cast(transactionid      as integer)        as transaction_id,
        cast(documentid         as integer)        as document_id,
        cast(contacttypeid      as integer)        as contact_type_id,
        -- status_id = 1 for all 57.7M records; no variability observed in current data
        cast(statusid           as integer)        as status_id,
        cast(orgname            as varchar)        as org_name,
        cast(orgkey             as varchar)        as org_key,
        cast(nametitle          as varchar)        as name_title,
        cast(namefirst          as varchar)        as first_name,
        cast(namemiddle         as varchar)        as middle_name,
        cast(namelast1          as varchar)        as last_name,
        cast(namelast2          as varchar)        as last_name_2,
        cast(namesuffix         as varchar)        as name_suffix,
        cast(namenick           as varchar)        as nickname,
        cast(email              as varchar)        as email,
        cast(phonebusiness      as varchar)        as phone_business,
        cast(phonemobile        as varchar)        as phone_mobile,
        cast(phonefax           as varchar)        as phone_fax,
        cast(addressline1       as varchar)        as address_line_1,
        cast(addressline2       as varchar)        as address_line_2,
        cast(addressline3       as varchar)        as address_line_3,
        cast(city               as varchar)        as city,
        cast(state              as varchar)        as state,
        cast(postalcode         as varchar)        as postal_code,
        cast(country            as varchar)        as country_code,
        cast(latitude           as float)          as latitude,
        cast(longitude          as float)          as longitude,
        cast(localecode         as varchar)        as locale_code,
        cast(website            as varchar)        as website,
        cast(comment            as varchar)        as comment,
        cast(createdby          as varchar)        as created_by,
        cast(updatedby          as varchar)        as updated_by,
        cast(createdon          as timestamp_ntz)  as created_at,
        cast(updatedon          as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced   as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
