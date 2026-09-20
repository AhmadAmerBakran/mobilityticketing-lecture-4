\set ON_ERROR_STOP on

update tickets t
set product_id = p.id
from products p
where t.product_id is null
  and p.code = t.product_code;
