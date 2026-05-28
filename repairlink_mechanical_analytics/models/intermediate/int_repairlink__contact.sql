{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_repairlink__contact') }}
),

-- Filter to rows that carry useful organizational context and have an org_key.
-- contact_id / transaction_id / document_id are NOT brought through —
-- this model is reusable enrichment, not a per-transaction grain.
filtered as (
    select *
    from source
    where org_key is not null
      and (first_name is not null
           or last_name  is not null
           or org_name   is not null)
),

normalized as (
    select
        org_key,
        contact_type_id,

        -- Text normalization
        upper(trim(org_name))                                            as org_name,
        name_title,
        initcap(trim(first_name))                                               as first_name,
        middle_name,
        initcap(trim(last_name))                                                as last_name,
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
        upper(trim(ltrim(city)))                                                as city,
        upper(trim(state))                                               as state,
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
),

-- One row per (org_key, contact_type_id) — pick the most recently updated.
-- Tiebreaker is the contact row with more populated identifying fields.
deduped as (
    select *
    from normalized
    qualify row_number() over (
        partition by org_key, contact_type_id
        order by
            updated_at desc nulls last,
            (case when first_name      is not null then 1 else 0 end +
             case when last_name       is not null then 1 else 0 end +
             case when email           is not null then 1 else 0 end +
             case when phone_business  is not null then 1 else 0 end +
             case when address_line_1  is not null then 1 else 0 end) desc
    ) = 1
)

select * from deduped
