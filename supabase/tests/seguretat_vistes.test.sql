-- Tests pgTAP de seguretat: cap vista del public es pot escriure sense ser postgres.
begin;
create extension if not exists pgtap with schema extensions;
select plan(2);

select is(
  (select count(*)::int from information_schema.views where table_schema = 'public' and table_name = 'perfils_publics'),
  0, 'la vista perfils_publics ja no existeix');

select is(
  (select count(*)::int
     from information_schema.role_table_grants g
     join information_schema.views v on v.table_schema = g.table_schema and v.table_name = g.table_name
    where g.table_schema = 'public' and g.grantee in ('anon', 'authenticated')
      and g.privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')),
  0, 'anon i authenticated no poden escriure en cap vista');

select * from finish();
rollback;
