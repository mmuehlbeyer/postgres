-- pg_table_info.sql
-- script to get all tables with varchar columns 


-- get all tables with varchar columns
select  table_schema,table_name,column_name,data_type, character_maximum_length
from information_schema.columns 
where
-- table_schema='pe' and 
data_type='character varying'
and table_schema not in ('information_schema')
order by table_schema