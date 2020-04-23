/*collect postgres performance data
from pg_stat_statements or saved pg_stat_statements
query output with "" for CSV imports to Excel
all times in seconds
orderd descending by mean_time 
*/

--select all queries with INSERT statements
select queryid,'"'||query||'"',calls,(total_time/1000) as total_time ,(min_time/1000) as min_time,(max_time/1000) as max_time,(mean_time/1000) as mean_time from pg_stats_mm_230420 where query like 'INSERT%' order by mean_time desc;


--select all queries with SELECT statements
select queryid,'"'||query||'"',calls,(total_time/1000) as total_time ,(min_time/1000) as min_time,(max_time/1000) as max_time,(mean_time/1000) as mean_time from pg_stats_mm_230420 where query like 'SELECT%' order by mean_time desc;


