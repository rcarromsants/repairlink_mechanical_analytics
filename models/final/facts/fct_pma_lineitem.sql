{{ config(materialized='table') }}

select
    -- identity (composite PK: line_item_id + program_id)
    line_item_id,
    program_id,
    transaction_id,

    -- classification
    comparison_result_id,
    qualification_type_id,
    qualification_status_id,
    status_id,

    -- program detail
    program_value,
    program_match_message,
    program_display_text,
    part_num_oe_xref,
    is_show_columns,

    -- metadata
    created_by,
    updated_by,
    created_at,
    updated_at,
    ingested_at

from {{ ref('stg_repairlink__pma_lineitem') }}
