{{ config(materialized='view') }}

{%- set condition_filter = 'Opioid Use Disorder (OUD)' -%}

{%- set naltrexone_ndcs = (
    '00056001122', '00056001130', '00056001170', '00056007950', '00056008050', '00185003901',
    '00185003930', '00406009201', '00406009203', '00406117001', '00406117003', '00555090201',
    '00555090202', '00904703604', '16729008101', '16729008110', '42291063230', '43063059115',
    '47335032683', '47335032688', '50090286600', '50436010501', '51224020630', '51224020650',
    '51285027501', '51285027502', '52152010502', '52152010504', '52152010530', '54868557400',
    '63459030042', '63629104601', '63629104701', '65694010003', '65694010010', '65757030001',
    '65757030202', '68084029111', '68084029121', '68094085362', '68115068030'
    )
-%}

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
        , encounter.data_source
        , condition.code as condition_code
        , condition.code_type as condition_code_type
        , procedure.code as procedure_code
        , procedure.code_type as procedure_code_type
    from {{ var('encounter') }} as encounter
         left join {{ var('condition') }} as condition
             on encounter.encounter_id = condition.encounter_id
         left join {{ var('procedure') }}  as procedure
             on encounter.encounter_id = procedure.encounter_id

),

patient_medications as (

    select
          encounter_id
        , patient_id
        , coalesce(filled_date, paid_date) as encounter_start_date
        , ndc
        , data_source
    from {{ var('medication') }}

),

inclusions_diagnosis as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , patient_encounters.data_source
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.condition_code = chronic_conditions.code
    where chronic_conditions.inclusion_type = 'Include'
    and chronic_conditions.code_system = 'ICD-10-CM'

),

inclusions_procedure as (

    select
          patient_encounters.patient_id
        , patient_encounters.encounter_id
        , patient_encounters.encounter_start_date
        , patient_encounters.data_source
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_encounters
         inner join chronic_conditions
             on patient_encounters.procedure_code = chronic_conditions.code
    where chronic_conditions.inclusion_type = 'Include'
    and chronic_conditions.code_system in ('ICD-10-PCS', 'HCPCS')

),

/*
    Exclusion logic: Naltrexone NDCs are excluded if there is evidence of an alcohol or other drug use disorder where opioid DX is not present
    This CTE excludes medication encounters with the exception codes for Naltrexone. Those encounters will be evaluated separately.
*/
inclusions_medication as (
    select
          patient_medications.patient_id
        , patient_medications.encounter_id
        , patient_medications.encounter_start_date
        , patient_medications.data_source
        , chronic_conditions.chronic_condition_type
        , chronic_conditions.condition_category
        , chronic_conditions.condition
    from patient_medications
         inner join chronic_conditions
             on patient_medications.ndc = chronic_conditions.code
    where chronic_conditions.inclusion_type = 'Include'
    and chronic_conditions.code_system = 'NDC'
    and chronic_conditions.code not in {{ naltrexone_ndcs }}

),

/*
    Exclusion logic: Naltrexone NDCs are excluded if there is evidence of an alcohol or other drug use disorder where opioid DX is not present
    This CTE includes patients with evidence of the chronic conditions Alcohol Use Disorders or Drug Use Disorders.
*/
exclusions_other_chronic_conditions as (

    select distinct patient_id
    from {{ ref('stg_chronic_condition_all') }}
    where condition in (
          'Alcohol Use Disorders'
        , 'Drug Use Disorders'
    )

),

/*
    Exclusion logic: Naltrexone NDCs are excluded if there is evidence of an alcohol or other drug use disorder where opioid DX is not present
    This CTE creates the exclusion list which consists of patients with medication encounters for Naltrexone having
    Alcohol Use Disorder or Drug Use Disorder and missing the Opioid Use Disorder diagnosis codes.
*/
exclusions_medication as (
    select distinct
          patient_medications.patient_id
    from patient_medications
         inner join chronic_conditions
             on patient_medications.ndc = chronic_conditions.code
         inner join exclusions_other_chronic_conditions
             on patient_medications.patient_id = exclusions_other_chronic_conditions.patient_id
         left join inclusions_diagnosis
             on patient_medications.patient_id = inclusions_diagnosis.patient_id
    where chronic_conditions.inclusion_type = 'Include'
    and chronic_conditions.code_system = 'NDC'
    and chronic_conditions.code in {{ naltrexone_ndcs }}
    and inclusions_diagnosis.patient_id is null

),

inclusions_unioned as (

    select * from inclusions_diagnosis
    union
    select * from inclusions_procedure
    union
    select * from inclusions_medication

)

select distinct
      inclusions_unioned.patient_id
    , inclusions_unioned.encounter_id
    , inclusions_unioned.encounter_start_date
    , inclusions_unioned.chronic_condition_type
    , inclusions_unioned.condition_category
    , inclusions_unioned.condition
    , inclusions_unioned.data_source
from inclusions_unioned
     left join exclusions_medication
         on inclusions_unioned.patient_id = exclusions_medication.patient_id
where exclusions_medication.patient_id is null