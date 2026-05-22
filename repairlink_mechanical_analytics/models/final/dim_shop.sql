{{ config(materialized='table') }}

with source as (

    select *
    from {{ ref('int_repairlink__shop') }}

),

dimension as (

    select

        {{ dbt_utils.generate_surrogate_key(['shop_id']) }} as shop_key,

        shop_id,
        location_code,
        order_type,

        -- Organizational/contact enrichment
        contact_type_id,
        contact_type_name,
        org_name,
        first_name,
        last_name,
        email,
        phone_business,
        phone_mobile,
        phone_fax,
        address_line_1,
        address_line_2,
        address_line_3,
        city,
        state,
        postal_code,
        country_code,
        latitude,
        longitude,
        locale_code,
        website,
        created_at,
        updated_at

    from source

),

-- Unknown row for late-arriving facts
unknown_row as (

    select

        {{ dbt_utils.generate_surrogate_key(["'UNKNOWN'"]) }} as shop_key,

        'UNKNOWN'              as shop_id,
        null::varchar          as location_code,
        null::integer          as order_type,
        null::integer          as contact_type_id,
        null::varchar          as contact_type_name,
        'UNKNOWN'              as org_name,
        null::varchar          as first_name,
        null::varchar          as last_name,
        null::varchar          as email,
        null::varchar          as phone_business,
        null::varchar          as phone_mobile,
        null::varchar          as phone_fax,
        null::varchar          as address_line_1,
        null::varchar          as address_line_2,
        null::varchar          as address_line_3,
        null::varchar          as city,
        null::varchar          as state,
        null::varchar          as postal_code,
        null::varchar          as country_code,
        null::float            as latitude,
        null::float            as longitude,
        null::varchar          as locale_code,
        null::varchar          as website,
        null::timestamp_ntz    as created_at,
        null::timestamp_ntz    as updated_at

)

select * from dimension

union all

select * from unknown_row