\set ON_ERROR_STOP on

\if :{?ticket_id}
\else
\set ticket_id 'LAB04-OLD-1'
\endif

\if :{?ticket_code}
\else
\set ticket_code 'LAB04-CODE-OLD-1'
\endif

insert into tickets
    (id, user_id, trip_id, ticket_code, status, product_code,
     valid_from_utc, valid_to_utc, price, currency)
select :'ticket_id', user_id, trip_id, :'ticket_code', status, product_code,
       valid_from_utc, valid_to_utc, price, currency
from tickets
where id = 'TICKET-1';

select id, product_code, price, currency
from tickets
where id = :'ticket_id';
