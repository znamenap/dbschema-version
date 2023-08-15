create user [test_user_reader] without login with default_schema = [schema_version_tests];
go

grant connect to [test_user_reader] as [dbo];
go

alter role [schema_version_reader] add member [test_user_reader];
go
alter role [db_datareader] add member [test_user_reader];
go
