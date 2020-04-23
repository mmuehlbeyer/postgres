#postgres_cheat_sheet

--infos 
\conninfo

--show version
show server_version;

--show all settings
show all;
select * from pg_settings;

select * from   pg_settings where  name = 'max_connections';

--settings value and name 
select name,setting from pg_settings where name = 'max_connections';

--describe table
\d <table_name>
\d pg_settings

--show all databases
\l

--show user (describe user)
\du

--check activity
select * from pg_stat_activity 

--check ssl
select * from pg_stat_ssl

--check db stats
select * from pg_stat_database

--table stats
select * from pg_stat_all_tables

--index stats
select * from pg_stat_all_indexes

--move table to new ts
alter table large_table set tablespace big_tablespace;

--move all tablespaces
alter table all in tablespace mytbs1 set tablespace big_tablespace;


--file path für tabelle
select pg_relation_filepath('new_large_test');



--show database size pretty
select pg_size_pretty(pg_database_size('__database_name__'));

--show table size pretty
select pg_size_pretty(pg_total_relation_size('__table_name__'));

--archiver process
SELECT * FROM pg_stat_archiver;


--autovac settings
select schemaname
    ,relname
    ,n_live_tup
    ,n_dead_tup
    ,last_autovacuum
from pg_stat_all_tables
order by n_dead_tup
    /(n_live_tup
      * current_setting('autovacuum_vacuum_scale_factor')::float8
      + current_setting('autovacuum_vacuum_threshold')::float8)
     desc

--vacuum stuff 
select * from pg_stat_progress_vacuum


--dead tuples
select relname as tablename ,n_live_tup as livetuples ,n_dead_tup as deadtuples from pg_stat_user_tables;

select relname as objectname, pg_stat_get_live_tuples(c.oid) as livetuples ,pg_stat_get_dead_tuples(c.oid) as deadtuples from pg_class c;

--tables rows

select schemaname,relname,n_live_tup as estimatedcount from pg_stat_user_tables order by n_live_tup desc;

select reltuples::bigint as estimatedcount from pg_class where  oid = 'public.tablename'::regclass;

--all objects for specific user
select nsp.nspname as schemaname,cls.relname as objectname ,rol.rolname as objectowner
    ,case cls.relkind
        when 'r' then 'TABLE'
        when 'm' then 'MATERIALIZED_VIEW'
        when 'i' then 'INDEX'
        when 'S' then 'SEQUENCE'
        when 'v' then 'VIEW'
        when 'c' then 'TYPE'
        else cls.relkind::text
    end as objecttype
from pg_class cls join pg_roles rol on rol.oid = cls.relowner join pg_namespace nsp on nsp.oid = cls.relnamespace where nsp.nspname not in ('information_schema', 'pg_catalog') and nsp.nspname not like 'pg_toast%' and rol.rolname = 'postgres' order by nsp.nspname,cls.relname


--locks
select 
pl.pid as processid,psa.datname as databasename,
psa.usename as username,psa.application_name as applicationname,
ps.relname as objectname,
psa.query_start as querystarttime, 
psa.state as querystate,psa.query as sqlquery,
pl.locktype,pl.tuple as tuplenumber,
pl.mode as lockmode,pl.granted -- true if lock is held, false if lock is awaited
from pg_locks as pl 
left join pg_stat_activity as psa on pl.pid = psa.pid 
left join pg_class as ps on pl.relation = ps.oid

--blocking transactions
select 
	pl.pid as blocked_pid
	,psa.usename as blocked_user
	,pl2.pid as blocking_pid
	,psa2.usename as blocking_user
	,psa.query as blocked_statement
from pg_catalog.pg_locks pl
join pg_catalog.pg_stat_activity psa
	on pl.pid = psa.pid
join pg_catalog.pg_locks pl2
join pg_catalog.pg_stat_activity psa2
	on pl2.pid = psa2.pid
	on pl.transactionid = pl2.transactionid 
		and pl.pid != pl2.pid
where not pl.granted;


--change schema name
update pg_catalog.pg_type
set typnamespace = (select oid from pg_catalog.pg_namespace
                    where nspname = 'destination_schema')
where typnamespace = (select oid from pg_catalog.pg_namespace
                      where nspname = 'source_schema')
and typname = 'table_name';


update pg_catalog.pg_class
set relnamespace = (select oid from pg_catalog.pg_namespace
                    where nspname = 'destination_schema')
where relnamespace = (select oid from pg_catalog.pg_namespace
                      where nspname = 'source_schema')
and relname = 'table_name';


--running queries

select pg_stat_get_backend_pid(s.backendid) as procpid, 
  pg_stat_get_backend_activity(s.backendid) as current_query
from (select pg_stat_get_backend_idset() as backendid) as s;


--queries at a db
select datname, application_name, pid, backend_start, query_start, state_change, state, query 
  from pg_stat_activity 
  where datname='__database_name__';

  --waiting queries
  select * from pg_stat_activity where waiting='t'


  --index scan ratio

select relname,idx_scan::float/(idx_scan+seq_scan+1) as idx_scan_ratio from pg_stat_all_tables
where schemaname=’public’
order by idx_scan_ratio asc;

--reset stats
select pg_stat_statements_reset();