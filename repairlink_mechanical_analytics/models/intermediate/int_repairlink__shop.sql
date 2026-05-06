{{ config(materialized='table') }}

with shops as (
    select * from {{ ref('stg_repairlink__shopconfig') }}
),

deduped as (
    select *
    from shops
    qualify row_number() over (
        partition by shop_id
        order by updated_at desc
    ) = 1
)

select * from deduped
