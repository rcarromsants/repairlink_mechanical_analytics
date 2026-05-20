{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__contact') }}
),

-- Filter to contacts with at least a name or org_name to ensure minimum data quality.
-- contact_id is already unique (no dedup needed); this is a transactional entity,
-- not a deduplicated person/org registry.
filtered as (
    select *
    from source
    where
        first_name is not null
        or last_name is not null
        or org_name is not null
        --and contact_type_id != 102 
),

final as (
    select
        contact_id,
        transaction_id,
        document_id,
        contact_type_id,
        -- Text normalization
        -- org_name: uppercased, leading spaces removed
        upper(ltrim(org_name))                              as org_name,
        org_key,
        name_title,
        initcap(first_name)                                 as first_name,
        middle_name,
        initcap(last_name)                                  as last_name,
        last_name_2,
        name_suffix,
        nickname,
        email,
        phone_business,
        phone_mobile,
        phone_fax,
        address_line_1,
        upper(trim(regexp_replace(regexp_replace(
                regexp_replace(
                    address_line_2,
                    '\\bSTE\\b',
                    'SUITE'
                ), '[-\\.\\#]',''),'\\s+',' '))) as address_line_2,
        address_line_3,
        upper(ltrim(city))                                  as city,
        upper(ltrim(state))                                 as state,
        postal_code,
        country_code,
        latitude,
        longitude,
        locale_code,
        website,
        created_at,
        updated_at,
        ingested_at
    from filtered
)

select * from final
