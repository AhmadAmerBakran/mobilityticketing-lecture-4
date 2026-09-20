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

\set ticket_id 'LAB04-ID-ONLY-1'
\set ticket_code 'LAB04-CODE-ID-ONLY-1'
\ir final_writer.sql
\ir final_reader.sql

rollback;
