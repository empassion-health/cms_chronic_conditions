{{ config(enabled = var('cms_chronic_conditions_enabled',var('tuva_packages_enabled',True)) ) }}

with chronic_conditions as (

    select distinct
          condition
        , condition_column_name
    from {{ ref('terminology__cms_chronic_conditions') }}

),

conditions as (

    select
          chronic_conditions_unioned.patient_id
        , chronic_conditions.condition_column_name
        , 1 as condition_count
    from {{ ref('cms_chronic_conditions__chronic_conditions_unioned') }} as chronic_conditions_unioned
         inner join chronic_conditions as chronic_conditions
             on chronic_conditions_unioned.condition =
                chronic_conditions.condition

)


   select
    patient_id
    , {{ dbt_utils.pivot(
          column='condition_column_name'
        , values=dbt_utils.get_column_values(ref ('terminology__cms_chronic_conditions'), 'condition_column_name', order_by= 'condition_column_name')
        , agg='max'
        , then_value= 1
        , else_value= 0
      ) }}
from conditions
group by
    patient_id

