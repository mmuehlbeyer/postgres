# confiure pgaudit and pgauditlog

pgaudit is quite useful for auditing postgres clusters
here is a short doc how to install pgaudit in combination with pgauditlogtofile

### install needes os packages 

```bash
#postgres 13
yum install pgaudit15_13
yum install pgauditlogtofile_13

# postgres 14
sudo yum install pgaudit16_14
yum install pgauditlogtofile_14
```

### adapt shared_preload_libaries
```
shared_preload_libraries='pgaudit,pgauditlogtofile'
```

### restart postgres cluster
```bash
pg_ctl restart
```

### config pgaudit in postgresql.conf 

e.g auditing ddl, role, and misc only

```
pgaudit.log = 'ddl,role,misc,misc_set'
pgaudit.log_catalog = off 
pgaudit.log_relation = 'on'
pgaudit.log_parameter = 'on'
```


### set the audit info to a separate logfile

add the following to postgresql.conf
```
pgaudit.log_directory='/var/log/postgres/$dbname/log'
pgaudit.log_filename='pgaudit-%d.log'
```