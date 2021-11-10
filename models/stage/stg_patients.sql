

{{ config(materialized='table') }}

select
    cast(member_id as string) as patient_id,
    cast(gender_code as string) as gender,
    to_date(birth_date) as birth_date,
    to_date(deceased_date) as deceased_date
from hcup.public.members
