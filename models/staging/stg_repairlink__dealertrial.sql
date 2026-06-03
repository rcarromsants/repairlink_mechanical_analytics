{{ config(materialized='incremental', unique_key='dealer_trial_id') }}

with source as (
    select * from {{ source('repairlink', 'DEALERTRIAL') }}
    {% if is_incremental() %}
    where _fivetran_synced > (select max(ingested_at) from {{ this }})
    {% endif %}
),

renamed as (
    select
        cast(dealertrialid      as integer)        as dealer_trial_id,
        cast(dealerid           as varchar)        as dealer_id,
        cast(statusid           as integer)        as status_id,
        cast(trialstartatutc    as timestamp_ntz)  as trial_started_at,
        cast(trialendatutc      as timestamp_ntz)  as trial_ended_at,
        cast(createdonutc       as timestamp_ntz)  as created_at,
        cast(updatedonutc       as timestamp_ntz)  as updated_at,
        cast(_fivetran_synced   as timestamp_tz)   as ingested_at
    from source
    where not _fivetran_deleted
)

select * from renamed
