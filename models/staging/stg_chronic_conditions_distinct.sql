{{ config(materialized='view') }}

with seed as (

    select * from {{ ref('chronic_conditions') }}

)

select distinct
      condition_id
    , condition
    , condition_column_name
    , chronic_condition_type
    , condition_category
from seed