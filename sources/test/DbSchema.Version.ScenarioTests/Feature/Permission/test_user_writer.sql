create user [test_user_writer] without login with default_schema = [schema_version_tests];
go

grant connect to [test_user_writer];
go

alter role [schema_version_reader] add member [test_user_writer];
go
alter role [schema_version_writer] add member [test_user_writer];
go
alter role [db_datareader] add member [test_user_writer];
go
alter role [db_datawriter] add member [test_user_writer];
go
