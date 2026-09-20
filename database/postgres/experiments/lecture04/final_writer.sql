\set ON_ERROR_STOP on

\if :{?ticket_id}
\else
\set ticket_id 'LAB04-ID-ONLY-1'
\endif

\if :{?ticket_code}
\else
\set ticket_code 'LAB04-CODE-ID-ONLY-1'
\endif

\if :{?product_id}
\else
select id as product_id
from products
where code = 'SINGLE'
\gset
\endif

\if :{?agreed_price}
\else
\set agreed_price '36.00'
\endif

\if :{?currency}
\else
\set currency 'DKK'
\endif

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select :'ticket_id', source.user_id, source.trip_id, :'ticket_code', source.status,
       :'product_id'::uuid, source.valid_from_utc, source.valid_to_utc,
       :'agreed_price'::numeric, :'currency'
from tickets source
where source.id = 'TICKET-1';

select id, product_id, price, currency
from tickets
where id = :'ticket_id';
