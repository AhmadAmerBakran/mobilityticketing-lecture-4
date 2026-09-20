\set ON_ERROR_STOP on

begin;

alter table tickets
    drop column product_code;

-- This is the old reader. It fails as soon as product_code is removed.
select id, product_code, price, currency
from tickets
order by id;

rollback;
