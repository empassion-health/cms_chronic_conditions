
{{ config(materialized='table') }}

select
    encounter_id
,   procedure_code
,   procedure_code_ranking
from hcup.public.procedures