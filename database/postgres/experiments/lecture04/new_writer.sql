\set ON_ERROR_STOP on

\if :{?ticket_id}
\else
\set ticket_id 'LAB04-NEW-1'
\endif

\if :{?ticket_code}
\else
\set ticket_code 'LAB04-CODE-NEW-1'
\endif

\if :{?product_id}
\else
select id as product_id
from products
where code = 'SINGLE'
\gset
\endif

\if :{?caller_product_code}
\else
\set caller_product_code 'SINGLE'
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
    (id, user_id, trip_id, ticket_code, status, product_code, product_id,
     valid_from_utc, valid_to_utc, price, currency)
select :'ticket_id', source.user_id, source.trip_id, :'ticket_code', source.status,
       p.code, p.id, source.valid_from_utc, source.valid_to_utc,
       :'agreed_price'::numeric, :'currency'
from tickets source
join products p on p.id = :'product_id'::uuid
where source.id = 'TICKET-1';

-- The caller's code is not trusted for storage. The code comes from the product row.
select :'caller_product_code' as caller_product_code,
       t.id,
       t.product_code as stored_product_code,
       t.product_id,
       t.price,
       t.currency
from tickets t
where t.id = :'ticket_id';
