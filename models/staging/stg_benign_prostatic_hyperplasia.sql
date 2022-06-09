--TODO: delete model
{{ config(enabled=false) }}
{{ config(materialized='view') }}

{% set condition_var = ['Benign Prostatic Hyperplasia'] %}

with chronic_conditions as (

    select * from {{ ref('chronic_conditions') }}

),

patient_encounters as (

    select
          encounter.patient_id
        , encounter.encounter_id
        , encounter.encounter_start_date
        , encounter.encounter_type
        , condition.code
        , condition.diagnosis_rank
    from {{ var('encounter') }} as encounter
         left join {{ var('condition') }} as condition
             on encounter.encounter_id = condition.encounter_id

),

inclusions as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , encounter.encounter_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.code = chronic_conditions.code
             and chronic_conditions.condition = condition_var
             and chronic_conditions.inclusion_type = 'Include'

),

exclusions as (

    select distinct patient_encounters.encounter_id
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.code = chronic_conditions.code
    where chronic_conditions.condition = condition_var
    and chronic_conditions.inclusion_type = 'Exclude'

),

select distinct
      inclusions.patient_id
    , inclusions.encounter_id
    , inclusions.encounter_start_date
    , inclusions.condition_category
    , inclusions.condition
from inclusions
     left join exclusions
         on inclusions.encounter_id = exclusions.encounter_id
where exclusions.encounter_id is null