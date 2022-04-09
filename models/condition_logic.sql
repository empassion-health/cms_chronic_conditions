{{ config(materialized='view') }}

with patients as (
select
    a.patient_id
,   a.encounter_id
,   a.encounter_start_date
,   b.code
,   b.diagnosis_rank
from {{ var('encounter') }}  a
    on a.patient_id = b.patient_id    
left join {{ var('condition') }} b
    on b.encounter_id = c.encounter_id
)

select
    a.patient_id
,   a.encounter_id
,   a.encounter_start_date
,   condition_category
,   condition
from patients a
inner join {{ ref('chronic_conditions') }} b
    on a.code = b.code
    and a.diagnosis_rank in (1,2)
    and b.condition = 'Acute Myocardial Infarction'
    and b.inclusion_type = 'Include'

    
union

select
    a.patient_id
,   a.encounter_id
,   a.encounter_start_date
,   condition_category
,   condition
from patients a
inner join {{ ref('chronic_conditions') }} b
    on a.code = b.code
    and a.diagnosis_rank in (1,2)
    and b.condition = 'Atrial Fibrillation'
    and b.inclusion_type = 'Include'
    
union

select
    a.patient_id
,   a.encounter_id
,   a.encounter_start_date
,   condition_category
,   condition
from patients a
inner join {{ ref('chronic_conditions') }} b
    on a.code = b.code
    and a.diagnosis_rank = 1
    and b.condition = 'Cataract'
    and b.inclusion_type = 'Include'

union

select
    a.patient_id
,   a.encounter_id
,   a.encounter_start_date
,   condition_category
,   condition
from patients a
inner join {{ ref('chronic_conditions') }} b
    on a.code = b.code
    and a.diagnosis_rank = 1
    and b.condition = 'Glaucoma'
    and b.inclusion_type = 'Include'
