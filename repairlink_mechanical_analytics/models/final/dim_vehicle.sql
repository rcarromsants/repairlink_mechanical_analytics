{{ config(materialized='table') }}

with source as (
    select * from {{ ref('int_repairlink__vehicle') }}
),

dimension as (
    select
        {{ dbt_utils.generate_surrogate_key(['vin']) }} as vehicle_key,
        vin,
        vehicle_id,
        transaction_id,
        vehicle_type_id,
        status_id,
        vehicle_year,
        -- Original RepairLink values (from staging — kept for comparison until DAT-2341 resolves VIN intel coverage)
        vehicle_make,
        vehicle_model,
        -- Canonical values from VIN intelligence enrichment
        vehicle_make_vintelligence,
        vehicle_model_vintelligence,
        vin_vintelligence,
        vin_decoded_correctly,
        created_at,
        updated_at,
        ingested_at
    from source
),

-- Unknown row for late-arriving facts
unknown_row as (
    select
        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as vehicle_key,
        'UNKNOWN'                as vin,
        null::integer            as vehicle_id,
        null::integer            as transaction_id,
        null::integer            as vehicle_type_id,
        null::integer            as status_id,
        null::integer            as vehicle_year,
        'Unknown'                as vehicle_make,
        'Unknown'                as vehicle_model,
        null::varchar            as vehicle_make_vintelligence,
        null::varchar            as vehicle_model_vintelligence,
        null::varchar            as vin_vintelligence,
        false                    as vin_decoded_correctly,
        null::timestamp_ntz      as created_at,
        null::timestamp_ntz      as updated_at,
        null::timestamp_tz       as ingested_at
)

select * from dimension
union all
select * from unknown_row

-- Removed columns from int_vehicle: odometer_reading, plate_* (all 100% null in dev),
-- vin_source / body_trim_code / paint_exterior_color_code / document_id / owner_id (100% null),
-- vin_suffix_* (testing only, will be removed from int_vehicle later).
