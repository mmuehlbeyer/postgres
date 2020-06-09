with table_opts as (
  select
    pg_class.oid, relname, nspname, array_to_string(reloptions, '') as relopts
  from
     pg_class inner join pg_namespace ns on relnamespace = ns.oid
), vacuum_settings as (
  select
    oid, relname, nspname,
    case
      when relopts like '%autovacuum_analyze_threshold%'
        then substring(relopts, '.*autovacuum_analyze_threshold=([0-9.]+).*')::integer
        else current_setting('autovacuum_analyze_threshold')::integer
      end as autovacuum_analyze_threshold,
    case
      when relopts like '%autovacuum_analyze_scale_factor%'
        then substring(relopts, '.*autovacuum_analyze_scale_factor=([0-9.]+).*')::real
        else current_setting('autovacuum_analyze_scale_factor')::real
      end as autovacuum_analyze_scale_factor
  from
    table_opts
)
select
  vacuum_settings.relname as table,
  to_char(psut.last_analyze, 'yyyy-mm-dd hh24:mi') as last_analyze,
  to_char(psut.last_autoanalyze, 'yyyy-mm-dd hh24:mi') as last_autoanalyze,
  to_char(pg_class.reltuples, '9g999g999g999') as rowcount,
  to_char(pg_class.reltuples / nullif(pg_class.relpages, 0), '999g999.99') as rows_per_page,
  to_char(autovacuum_analyze_threshold
       + (autovacuum_analyze_scale_factor::numeric * pg_class.reltuples), '9g999g999g999') as autovacuum_analyze_threshold,
  case
    when autovacuum_analyze_threshold + (autovacuum_analyze_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup
    then 'yes'
  end as will_analyze
from
  pg_stat_user_tables psut inner join pg_class on psut.relid = pg_class.oid
    inner join vacuum_settings on pg_class.oid = vacuum_settings.oid
order by 1