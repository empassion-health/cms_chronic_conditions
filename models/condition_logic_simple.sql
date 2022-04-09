{{ config(materialized='view') }}

with diagnosis_conditions as (
select
    a.patient_id
,   a.encounter_id
,   a.encounter_start_date
,   c.condition_category
,   c.condition
from {{ var('encounter') }} a
inner join {{ var('condition') }}  b
    on a.encounter_id = b.encounter_id
inner join {{ ref('chronic_conditions') }}  c
    on b.code = c.code
    and c.code_type = 'icd-10-cm'
    and c.inclusion_type = 'Include'
    and c.additional_logic = 'None'
)
    
, procedure_conditions as (
select
    a.patient_id
,   a.encounter_id
,   a.encounter_start_date
,   c.condition_category
,   c.condition
from patients a
inner join {{ var('procedure') }}  b
    on a.encounter_id = b.encounter_id
inner join {{ ref('chronic_conditions') }}  c
    on b.code = c.code
    and c.code_type = 'icd-10-pcs'
    and c.inclusion_type = 'Include'
    and c.additional_logic = 'None'
)

select *
from diagnosis_conditions

union

select *
from procedure_conditions