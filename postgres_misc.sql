#postgres misc collection

--connect
psql -d edb -U enterprisedb



edb=# show data_directory;
     data_directory
------------------------
 /var/lib/edb/as11/data
(1 row)



select name,setting from pg_settings;


select current_user;
select current_database();


select spcname from pg_tablespace;

select * from pg_tablespace;

postgres=# select * from pg_tablespace;
  spcname   | spcowner | spcacl | spcoptions
------------+----------+--------+------------
 pg_default |       10 |        |
 pg_global  |       10 |        |



postgres=# \db
       List of tablespaces
    Name    |  Owner   | Location
------------+----------+----------
 pg_default | postgres |
 pg_global  | postgres |


 CREATE TABLE foo
(
    i integer
)
WITH (
    OIDS = FALSE
)
TABLESPACE my_test;