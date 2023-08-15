
print 'Testing [schema_version].[register_downgrade_step]'
set nocount on;
declare @error as varchar(2048);
declare @mystep as [schema_version].[t_step];

insert into @mystep (
      [version] -- [schema_version].[t_version] not null
    , [sequence] -- smallint not null
    , [description] -- nvarchar(128) not null
    , [procedure] -- [sys].[sysname] not null
    ) values 
    ( 1, 1, 'description', 'procedure_name' );
exec [schema_version_tests].[recreate_dummy_steps] @schema = '[dbo]', @steps = @mystep;

print '    ... @schema_name is null'
begin try
    exec [schema_version].[register_downgrade_step] 
        @schema_name = null,
        @application_name = 'tests', 
        @step = @mystep;
    throw 50000, 'Test failed, expected exception did not happen.', 1;
end try
begin catch
    if error_message() not like '%null argument value%'
    begin
        set @error = concat('Expecting %%null argument%% exception, but received:', error_message());
        throw 50000, @error, 1;
    end
end catch

print '    ... @application_name is null'
begin try
    exec [schema_version].[register_downgrade_step] 
        @schema_name = '[dbo]',
        @application_name = null, 
        @step = @mystep;
    throw 50000, 'Test failed, expected exception did not happen.', 1;
end try
begin catch
    if error_message() not like '%null argument value%'
    begin
        set @error = concat('Expecting %%null argument%% exception, but received:', error_message());
        throw 50000, @error, 1;
    end
end catch


print '    ... @step is null'
declare @empty_step as [schema_version].[t_step];
begin try
    exec [schema_version].[register_downgrade_step] 
        @schema_name = '[dbo]',
        @application_name = 'myapp', 
        @step = @empty_step;
    throw 50000, 'Test failed, expected exception did not happen.', 1;
end try
begin catch
    if error_message() not like '%null argument value%'
    begin
        set @error = concat('Expecting %%null argument%% exception, but received:', error_message());
        throw 50000, @error, 1;
    end
end catch

print '    ... myapp, [dbo] and version was registered for downgrade step.'
delete [schema_version].[step]
    where [application_name] = 'myapp' and [schema_name] = '[dbo]' and [version] = 1 and [upgrade] = 0;

exec [schema_version].[register_downgrade_step] 
    @schema_name = '[dbo]',
    @application_name = 'myapp', 
    @step = @mystep;

if not exists(select [sequence] from [schema_version].[step] 
    where [application_name] = 'myapp' and [schema_name] = '[dbo]' and [version] = 1 and [upgrade] = 0)
    throw 50000, 'The registered app was not found',1;

execute [sys].[sp_executesql] @statement = N'drop procedure [dbo].[procedure_name]';
go
