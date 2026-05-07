{{ config(materialized='incremental', unique_key='vehicle_id') }}

with source as (
    select * from {{ source('repairlink', 'TRANSACTION_ENT_VEHICLE') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(vehicleid                  as integer)        as vehicle_id,
        cast(transactionid              as integer)        as transaction_id,
        cast(documentid                 as integer)        as document_id,
        cast(vehicletypeid              as integer)        as vehicle_type_id,
        cast(statusid                   as integer)        as status_id,
        cast(ownerid                    as integer)        as owner_id,
        cast(vinnumber                  as varchar)        as vin,
        -- vin_decoded_correctly is always false in current data (no VIN decoding implemented)
        cast(vindecodedcorrectly        as boolean)        as vin_decoded_correctly,
        cast(vinsource                  as varchar)        as vin_source,
        -- vehicle_year = 0 is used as a sentinel for unknown year; values up to 2027 exist (future model years)
        cast(vehicleyear                as integer)        as vehicle_year,
        cast(vehiclemake                as varchar)        as vehicle_make,
        cast(vehiclemodel               as varchar)        as vehicle_model,
        cast(bodytrimcode               as varchar)        as body_trim_code,
        cast(paintexteriorcolorcode     as varchar)        as paint_exterior_color_code,
        -- odometer_reading and all plate_* fields are always null in current data
        cast(vehicleodometerreading     as varchar)        as odometer_reading,
        cast(platenumber                as varchar)        as plate_number,
        cast(platetype                  as varchar)        as plate_type,
        cast(platestateprovince         as varchar)        as plate_state_province,
        cast(platecountrycodeid         as integer)        as plate_country_code_id,
        cast(plateexpirationdate        as timestamp_ntz)  as plate_expiration_date,
        cast(timeautopickup             as timestamp_ntz)  as auto_pickup_at,
        cast(timeautodropoff            as timestamp_ntz)  as auto_dropoff_at,
        cast(createdby                  as varchar)        as created_by,
        cast(updatedby                  as varchar)        as updated_by,
        cast(createdon                  as timestamp_ntz)  as created_at,
        cast(updatedon                  as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced           as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
