{{ config(materialized='table') }}

{% set condition_filter = 'Human Immunodeficiency Virus and/or Acquired Immunodeficiency Syndrome (HIV/AIDS)' %}

with chronic_conditions as (

    select * from {{ ref('chronic_conditions') }}
    where condition = '{{ condition_filter }}'

),

patient_encounters as (

    select
          encounter.patient_id
        , encounter.encounter_id
        , encounter.encounter_start_date
        , encounter.ms_drg
        , diagnosis.code as diagnosis_code
        , diagnosis.code_type as diagnosis_code_type
    from {{ var('encounter') }} as encounter
         left join {{ var('condition') }} as diagnosis /* using alias to differentiate from chronic condition terms */
             on encounter.encounter_id = diagnosis.encounter_id

),

/*
    This condition has an exception: A claim with the diagnosis code R75 requires a second qualifying claim that is not R75 (a screening code)
    This CTE excludes encounters with the exception code. Those encounters will be evaluated separately.
*/
inclusions_diagnosis as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.diagnosis_code = chronic_conditions.code
    where chronic_conditions.inclusion_type = 'Include'
    and chronic_conditions.code_system = 'ICD-10-CM'
    and chronic_conditions.code <> 'R75'

),

inclusions_ms_drg as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.ms_drg = chronic_conditions.code
    where chronic_conditions.inclusion_type = 'Include'
    and chronic_conditions.code_system = 'MS-DRG'

),

/*
    This condition has an exception: A claim with the diagnosis code R75 requires a second qualifying claim that is not R75 (a screening code)
    This CTE includes encounters with the exception code only where that patient has another encounter that is not R75.
*/
exception_diagnosis as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.diagnosis_code = chronic_conditions.code
         inner join inclusions_diagnosis
             on patient_encounters.patient_id = inclusions_diagnosis.patient_id
    where chronic_conditions.inclusion_type = 'Include'
    and chronic_conditions.code_system = 'ICD-10-CM'
    and chronic_conditions.code = 'R75'

),

inclusions_unioned as (

    select * from inclusions_diagnosis
    union
    select * from inclusions_ms_drg
    union
    select * from exception_diagnosis

)

select distinct
      inclusions_unioned.patient_id
    , inclusions_unioned.encounter_id
    , inclusions_unioned.encounter_start_date
    , inclusions_unioned.chronic_condition_type
    , inclusions_unioned.condition_category
    , inclusions_unioned.condition
from inclusions_unioned
