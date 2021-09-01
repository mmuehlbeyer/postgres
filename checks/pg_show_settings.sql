-- postgres show settings
-- mm 09/2021
-- show specific settings 
-- adapt name to your needs

SELECT name, current_setting(name), source, sourcefile, sourceline FROM pg_settings WHERE name like ('log_%');