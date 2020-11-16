CREATE PROCEDURE [schema_version_tests].[recreate_dummy_steps]
    @schema [sys].[sysname]
  , @steps [schema_version].[t_step] readonly
AS
begin
    declare @procedure_name [sys].[sysname];
    declare @object_name [sys].[sysname];
    declare step_cursor cursor forward_only read_only for
        select [s].[procedure] from @steps as [s];
    open [step_cursor];
    fetch next from [step_cursor] into @procedure_name;
    while @@fetch_status = 0
    begin
        set @procedure_name = @schema+'.['+@procedure_name+']';
        execute [schema_version_tests].[recreate_dummy_stored_procedure] @name = @procedure_name;
        declare @grant_perm nvarchar(1024) = 'grant execute on ' + @procedure_name + ' to [test_user_writer], [test_user_owner]';
        execute [sys].[sp_executesql] @statement = @grant_perm;
        fetch next from [step_cursor] into @procedure_name;
    end;
    close [step_cursor];
    deallocate [step_cursor];
end;
