create procedure [schema_version_tests].[recreate_dummy_stored_procedure]
    @name [sys].[sysname]
as
begin

    declare @drop nvarchar(512) = N' if object_id(''' + @name + ''', ''P'') is not null  drop procedure ' + @name;
    declare @create nvarchar(512) = N'create procedure ' + @name + ' as begin return 0; end;';

    execute [sys].[sp_executesql] @statement = @drop;
    execute [sys].[sp_executesql] @statement = @create;

end;