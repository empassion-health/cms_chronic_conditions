{{ config(materialized='table') }}

with conditions_unioned as (

    select *
    from {{ ref('stg_chronic_condition_all') }}

    union

    select *
    from {{ ref('stg_chronic_condition_hiv_aids') }}

    union

    select *
    from {{ ref('stg_chronic_condition_oud') }}

)

select
      patient_id
    , encounter_id
    , encounter_start_date
    , chronic_condition_type
    , condition_category
    , condition
    , data_source
from conditions_unioned