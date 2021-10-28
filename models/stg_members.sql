

{{ config(materialized='table') }}

select
    member_id
,   gender_code
,   birth_date
,   deceased_date
from hcup.public.members