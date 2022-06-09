--TODO: Add additional logic for this condition

{{ config(materialized='table') }}

{% set condition_filter = 'Human Immunodeficiency Virus and/or Acquired Immunodeficiency Syndrome (HIV/AIDS)' %}

with chronic_conditions as (

    select * from {{ ref('chronic_conditions') }}

),

patient_encounters as (

    select
          encounter.patient_id
        , encounter.encounter_id
        , encounter.encounter_start_date
        , encounter.encounter_type
        , encounter.ms_drg
        , diagnosis.code as diagnosis_code
        , diagnosis.code_type as diagnosis_code_type
        , procedure.code as procedure_code
        , procedure.code_type as procedure_code_type
    from {{ var('encounter') }} as encounter
         left join {{ var('condition') }} as diagnosis /* using alias to differentiate from chronic condition terms */
             on encounter.encounter_id = diagnosis.encounter_id
         left join {{ var('procedure') }}  as procedure
             on encounter.encounter_id = procedure.encounter_id

),

inclusions_diagnosis as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , patient_encounters.encounter_type
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.diagnosis_code = chronic_conditions.code
             and chronic_conditions.inclusion_type = 'Include'
    where chronic_conditions.condition = condition_filter

),

inclusions_ms_drg as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , patient_encounters.encounter_type
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.ms_drg = chronic_conditions.code
             and chronic_conditions.inclusion_type = 'Include'
    where chronic_conditions.condition = condition_filter

),

exclusions_diagnosis as (

    select distinct
          patient_encounters.encounter_id
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.diagnosis_code = chronic_conditions.code
    where chronic_conditions.inclusion_type = 'Exclude'
    and chronic_conditions.condition = condition_filter

),

inclusions_unioned as (

    select * from inclusions_diagnosis
    union
    select * from inclusions_ms_drg

)

select distinct
      inclusions_unioned.patient_id
    , inclusions_unioned.encounter_id
    , inclusions_unioned.encounter_start_date
    , inclusions_unioned.encounter_type
    , inclusions_unioned.chronic_condition_type
    , inclusions_unioned.condition_category
    , inclusions_unioned.condition
from inclusions_unioned
     left join exclusions_diagnosis
         on inclusions_unioned.encounter_id = exclusions_diagnosis.encounter_id
         and inclusions_unioned.condition = exclusions_diagnosis.condition
where exclusions_diagnosis.encounter_id is null