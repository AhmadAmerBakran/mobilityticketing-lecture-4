\set ON_ERROR_STOP on

begin;

-- Both foreign keys still point to real products, so the database accepts this pair.
update tickets
set product_id = (select id from products where code = 'DAY')
where id = 'TICKET-1';

-- The verification query must find the mismatch.
select t.id, t.product_code, t.product_id, p.code as id_product_code
from tickets t
left join products p on p.id = t.product_id
where t.product_id is null
   or p.id is null
   or t.product_code is distinct from p.code
order by t.id;

rollback;
