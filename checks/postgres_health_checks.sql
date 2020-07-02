--postgres health checks
--Michael Muehlbeyer (mmi)
--internal use only

--check postgres version

select version(), current_setting('server_version_num'), current_setting('server_version');

--output as json
select
    json_build_object('version', version(),
        'server_version_num', current_setting('server_version_num'),
        'server_major_ver', (select regexp_replace(current_setting('server_version'), '\\.\\d+$', '')),
        'server_minor_ver', (select regexp_replace(current_setting('server_version'), '^.*\\.', '')));

select json_object_agg(s.name, s) from (select * from pg_settings s order by category, name) s;

-- get db name
select 'DB name' as metric, datname as value from data;

-- select startup time & uptime
select 'started at', pg_postmaster_start_time()::timestamptz(0)::text
union all
select 'uptime', (now() - pg_postmaster_start_time())::interval(0)::text;


-- some checkpoint information
  select
    'checkpoints',
    (select (checkpoints_timed + checkpoints_req)::text from pg_stat_bgwriter)
  union all
  select
    'forced checkpoints',
    (
      select round(100.0 * checkpoints_req::numeric /(nullif(checkpoints_timed + checkpoints_req, 0)), 1)::text || '%'from pg_stat_bgwriter
    )
  union all
  select
    'checkpoint mb/sec',
    (select round((nullif(buffers_checkpoint::numeric, 0) /((1024.0 * 1024 /(current_setting('block_size')::numeric))* extract('epoch' from now() - stats_reset)))::numeric, 6)::text
      from pg_stat_bgwriter);


--some memory related paramters
select name, setting from pg_settings s where name in (
        'max_connections',
        'work_mem',
        'maintenance_work_mem',
        'autovacuum_work_mem',
        'shared_buffers',
        'effective_cache_size',
        'temp_buffers',
        'autovacuum_max_workers'
    );


-- check db size
select 'DB size', pg_size_pretty(pg_database_size(current_database()))



------------------------------------
--check cache hit ratio
-- should be around 99%
--if not increase cache size
select 
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit)  as heap_hit,
  sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio
from 
  pg_statio_user_tables;




--check top sql statements
-- limit to top 30 statements
-- exclude internal statements
-- limit to statements executed more than 300 times
select query, 
       calls, 
       total_time, 
       total_time / calls as time_per, 
       stddev_time, 
       rows, 
       rows / calls as rows_per,
       100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) as hit_percent
from pg_stat_statements
where query not similar to '%pg_%'
and calls > 300
order by time_per
desc limit 30;


-- check for dead rows
select relname, n_dead_tup from pg_stat_user_tables;

-- show largest tables
-- adjust limit for mor or less infos
select  relname as "table_name", pg_size_pretty(pg_table_size(c.oid)) as "table_size"
from pg_class c
left join pg_namespace n on (n.oid = c.relnamespace)
where nspname not in ('pg_catalog', 'information_schema') and nspname !~ '^pg_toast' and relkind in ('r')
order by pg_table_size(c.oid)
desc limit 5;

--table size includung indices
select c.relname as name,
  pg_size_pretty(pg_total_relation_size(c.oid)) as size
from pg_class c
left join pg_namespace n on (n.oid = c.relnamespace)
where n.nspname not in ('pg_catalog', 'information_schema') and n.nspname !~ '^pg_toast' and c.relkind='r'
order by pg_total_relation_size(c.oid) desc;

-- check unused indices
-- check for unused and rarely used indices
select  schemaname || '.' || relname as table,  indexrelname as index,  pg_size_pretty(pg_relation_size(i.indexrelid)) as index_size, idx_scan as index_scans
from pg_stat_user_indexes ui
join pg_index i on ui.indexrelid = i.indexrelid
where not indisunique  and idx_scan < 50   and pg_relation_size(relid) > 5 * 8192
order by pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) desc nulls first,
pg_relation_size(i.indexrelid) desc;

SELECT s.schemaname,
       s.relname AS tablename,
       s.indexrelname AS indexname,
       pg_relation_size(s.indexrelid) AS index_size,
       s.idx_scan
FROM pg_catalog.pg_stat_user_indexes s
   JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan < 10      -- has never been scanned/not scanned for more than 10 times
  AND 0 <>ALL (i.indkey)  -- no index column is an expression
  AND NOT i.indisunique   -- is not a UNIQUE index
  AND NOT EXISTS          -- does not enforce a constraint
         (SELECT 1 FROM pg_catalog.pg_constraint c
          WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;




-- last autovacuum run
-- it should run for all tables
-- at least for the frequent updated and large tables
select relname, last_vacuum, last_autovacuum from pg_stat_user_tables;


-- check autovacuum settings
select  name, setting from pg_settings where name like 'autovacuum%';

-- check autovacuum specific table
select reloptions from pg_class where relname='my_table';

--check if table needs vacuum
-- limit to 3 tables
-- adapt if needed
select schemaname , relname, n_dead_tup, n_live_tup, n_dead_tup > 0 as needs_vacuum from pg_stat_user_tables
order by n_dead_tup desc
limit 3;

-- table information
-- relevant for vacuum setting
-- high amount of updates --> vacuum necessary
select schemaname, relname , n_tup_ins as "inserts",n_tup_upd as "updates",n_tup_del as "deletes", n_live_tup as "live_tuples", n_dead_tup as "dead_tuples" from pg_stat_user_tables;




-- toast size by table
-- 
select c.relname as name,
  pg_size_pretty(pg_total_relation_size(reltoastrelid)) as toast_size
from pg_class c
left join pg_namespace n on n.oid = c.relnamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and n.nspname !~ '^pg_toast'
  and c.relkind = 'r'
order by pg_total_relation_size(reltoastrelid) desc nulls last;

--check current connections
select count(distinct(numbackends)) from pg_stat_database

-- current connections with username, pid,...
select pid as process_id, 
       usename as username, 
       datname as database_name, 
       client_addr as client_address, 
       application_name,
       backend_start,
       state,
       state_change
from pg_stat_activity;

--check for connections and remaining connections
select max_conn,used,res_for_super,max_conn-used-res_for_super res_for_normal 
from 
  (select count(*) used from pg_stat_activity) t1,
  (select setting::int res_for_super from pg_settings where name=$$superuser_reserved_connections$$) t2,
  (select setting::int max_conn from pg_settings where name=$$max_connections$$) t3;

-- connections with idle information and so on
select
    coalesce(usename, '** ALL users **') as "user",
    coalesce(datname, '** ALL databases **') as "database",
    coalesce(state, '** ALL states **') as "current_state",
    count(*) as "count",
    count(*) filter (where state_change < now() - interval '1 minute') as "state_changed_more_1m_ago",
    count(*) filter (where state_change < now() - interval '1 hour') as "state_changed_more_1h_ago",
    count(*) filter (where xact_start < now() - interval '1 minute') as "tx_age_more_1m",
    count(*) filter (where xact_start < now() - interval '1 hour') as "tx_age_more_1h"
  from pg_stat_activity
  group by grouping sets ((datname, usename, state), (usename, state), ())
  order by
    usename is null desc,
    datname is null desc,
    2 asc,
    3 asc,
    count(*) desc;
