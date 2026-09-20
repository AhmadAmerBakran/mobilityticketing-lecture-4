\set ON_ERROR_STOP on

select t.id, t.product_code, t.product_id, t.price, t.currency
from tickets t
order by t.id;

-- This must return no rows before product_id is made required.
select t.id, t.product_code, t.product_id
from tickets t
left join products p on p.id = t.product_id
where t.product_id is null
   or p.id is null
   or t.product_code is distinct from p.code
order by t.id;

-- The original tickets must still have the same product, price and currency.
with expected(id, product_code, price, currency) as (
    values
        ('TICKET-1', 'SINGLE', 36.00::numeric, 'DKK'),
        ('TICKET-2', 'SINGLE', 36.00::numeric, 'DKK'),
        ('TICKET-3', 'DAY',    65.00::numeric, 'DKK')
)
select e.id,
       e.product_code as expected_product_code,
       t.product_code as actual_product_code,
       e.price as expected_price,
       t.price as actual_price,
       e.currency as expected_currency,
       t.currency as actual_currency
from expected e
left join tickets t on t.id = e.id
where t.id is null
   or t.product_code is distinct from e.product_code
   or t.price is distinct from e.price
   or t.currency is distinct from e.currency
order by e.id;
