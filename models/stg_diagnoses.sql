
{{ config(materialized='table') }}

select
    encounter_id
,   diagnosis_code
,   diagnosis_code_ranking
,   present_on_admission_code
from hcup.public.diagnoses