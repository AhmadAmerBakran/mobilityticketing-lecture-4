\set ON_ERROR_STOP on

begin;
set local lock_timeout = '3s';

-- Database objects that still mention the old ticket column must be handled first.
select schemaname, viewname
from pg_views
where schemaname = 'public'
  and definition ilike '%product_code%'
order by viewname;

select routine_schema, routine_name
from information_schema.routines
where routine_schema = 'public'
  and routine_definition ilike '%product_code%'
order by routine_name;

alter table tickets
    drop column product_code;

-- Rehearse the ID-only writer after the old column is gone.
select id as test_product_id
from products
where code = 'SINGLE'
\gset

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select 'LAB04-ID-ONLY-1', source.user_id, source.trip_id,
       'LAB04-CODE-ID-ONLY-1', source.status, :'test_product_id'::uuid,
       source.valid_from_utc, source.valid_to_utc, 36.00, 'DKK'
from tickets source
where source.id = 'TICKET-1';

-- Rehearse the ID-only reader. products.code stays as a catalogue code.
select t.id,
       t.product_id,
       p.code as product_code,
       t.price,
       t.currency
from tickets t
join products p on p.id = t.product_id
order by t.id;

rollback;
