{{ config(materialized='table') }}

select
    vin,
    vehicle_id,
    transaction_id,
    vehicle_type_id,
    status_id,
    vehicle_year,

    -- Original RepairLink values
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

from {{ ref('int_repairlink__vehicle') }}