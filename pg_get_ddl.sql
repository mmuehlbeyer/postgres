-- postgresql get ddl collection
-- get ddl for several objects


-- get ddl for function
select proname
     , pg_get_functiondef(a.oid)
  from pg_proc a
 where a.proname like '%refresh_%';


 
