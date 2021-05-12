#!/bin/sh
export PGHOME="/usr/pgsql-13/"
export PATH="${PGHOME}/bin:${PATH}"
export PGDATABASE=db01
export PGPORT=20001

# cleanup older than 2 month
psql -c "delete from stat_statements_snapshots sss where sss.created <= (date_trunc('MONTH',current_date) - interval '2 MONTH')::date" >>/tmp/pg_stat_cleanup.log