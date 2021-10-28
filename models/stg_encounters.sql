
{{ config(materialized='table') }}

select
    encounter_id
,   member_id
,   encounter_start_date
,   encounter_end_date
,   admit_type_code
,   admit_source_code
,   discharge_status_code
from hcup.public.encounters