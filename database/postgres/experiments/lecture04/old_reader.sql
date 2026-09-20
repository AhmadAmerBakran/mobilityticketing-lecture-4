\set ON_ERROR_STOP on

select id, product_code, price, currency
from tickets
order by id;
