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



--move table to new ts
alter table large_table set tablespace big_tablespace;

--move all tablespaces
alter table all in tablespace mytbs1 set tablespace big_tablespace;


--file path für tabelle
SELECT pg_relation_filepath('new_large_test');

