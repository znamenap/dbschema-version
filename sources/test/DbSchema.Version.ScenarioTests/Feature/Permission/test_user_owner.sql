create user [test_user_owner] without login with default_schema = [schema_version_tests];
go

grant connect to [test_user_owner] as [dbo];
go

alter role [schema_version_reader] add member [test_user_owner];
go
alter role [schema_version_writer] add member [test_user_owner];
go
alter role [schema_version_owner] add member [test_user_owner];
go
alter role [db_datareader] add member [test_user_owner];
go
alter role [db_datawriter] add member [test_user_owner];
go
