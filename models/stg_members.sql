

{{ config(materialized='table') }}

select
    cast(member_id as string) as member_id,
    cast(gender_code as string) as gender_code,
    to_date(birth_date) as birth_date,
    to_date(deceased_date) as deceased_date
from hcup.public.members
