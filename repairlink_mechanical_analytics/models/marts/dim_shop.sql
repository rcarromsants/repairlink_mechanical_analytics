{{ config(materialized='table') }}

with shops as (
    select * from {{ ref('int_repairlink__shop') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['shop_id']) }} as shop_key,
        shop_id,
        location_code,
        order_type,
        created_at,
        updated_at
    from shops
)

select * from final
