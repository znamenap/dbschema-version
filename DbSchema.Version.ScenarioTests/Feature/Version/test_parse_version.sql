
print 'Testing to parse a version text to version number.'
declare @version_text as nvarchar(128) = '2020.1.1340';
declare @version_number [schema_version].[t_version];
exec schema_version.parse_version @version_text = @version_text           -- nvarchar(128)
                                , @version_number = @version_number output ;  -- decimal
print 'Result version number is ' + cast(@version_number as varchar(50)) + ' from ' + @version_text;
go
print 'Testing to parse a version text to version number with weighted base at 100 000.'
declare @version_text as nvarchar(128) = '20201.15894.1340'
declare @version_number [schema_version].[t_version];
exec schema_version.parse_version @version_text = @version_text           -- nvarchar(128)
                                , @weight_base = 100000
                                , @version_number = @version_number output ;  -- decimal
print 'Result version number is ' + cast(@version_number as varchar(50)) + ' from ' + @version_text;
go
