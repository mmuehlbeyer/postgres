-- postgres show non default settings
-- mm 09/2021
 SELECT name, current_setting(name), source, sourcefile, sourceline FROM pg_settings WHERE (source <> 'default' OR name = 'server_version') AND name NOT IN ('config_file', 'data_directory', 'hba_file', 'ident_file');