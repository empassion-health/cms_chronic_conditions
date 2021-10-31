

select *
from {{ ref('stg_members') }}
where (deceased_date is not null) and (birth_date > deceased_date)

