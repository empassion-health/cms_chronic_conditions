/* TODO: Run/test for loop and new CTEs */

{{ config(materialized='view') }}

/*
    logic:
    loop for code look up (dx, px, hcpcs, etc) and each unique condition (should each code lookup be it's own CTE or model?)
    find patient encounters with matching inclusion codes
    apply exclusions
    include in final output on encounter level
*/

with chronic_conditions as (

    select * from {{ ref('chronic_conditions') }}

),

chronic_conditions_distinct as (

    select * from {{ ref('stg_chronic_conditions_distinct') }}

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

),

inclusions_procedure as (

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
             on patient_encounters.procedure_code = chronic_conditions.code
             and chronic_conditions.inclusion_type = 'Include'

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

),

exclusions_diagnosis as (

    select distinct
          patient_encounters.encounter_id
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.diagnosis_code = chronic_conditions.code
    where chronic_conditions.inclusion_type = 'Exclude'

),

inclusions_unioned as (

    select * from inclusions_diagnosis
    union
    select * from inclusions_procedure
    union
    select * from inclusions_ms_drg

)

select distinct
      patient_encounters.patient_id
    , patient_encounters.encounter_id
    , patient_encounters.encounter_start_date
    , patient_encounters.encounter_type
    , chronic_conditions.chronic_condition_type
    , chronic_conditions.condition_category
    , chronic_conditions.condition
from inclusions_unioned
     left join exclusions
         on inclusions_unioned.encounter_id = exclusions_diagnosis.encounter_id
         and inclusions_unioned.condition = exclusions_diagnosis.condition
where exclusions_diagnosis.encounter_id is null