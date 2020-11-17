create procedure [schema_version].[invoke_step_procedure]
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
  , @version as [schema_version].[t_version]
  , @step_id as int
  , @step_version as [schema_version].[t_version]
  , @step_sequence as smallint
  , @step_description as nvarchar(128)
  , @step_procedure as [sys].[sysname]
  , @is_upgrade_direction as bit
  , @is_downgrade_direction as bit
as
begin
    set nocount on;
    declare @base_msg nvarchar(2048) =
        'step_id=' + cast(@step_id as varchar(38)) + ', '
        + @application_name
        + N'('+cast(@step_version as nvarchar(38))+N')+' + cast(@step_sequence as nvarchar(38))
        + N' via ' + @schema_name + N'.' + @step_procedure + '()';
    declare @msg nvarchar(2048) = 'EXEC: ' + @base_msg;
    exec [schema_version].[add_audit_event] @proc_id = @@procid, @message = @msg;
    begin try
        exec [sys].[sp_executesql] @sql = @step_procedure;
    end try
    begin catch
        declare @error_message nvarchar(2048);
        set @error_message = 'ERROR: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ') from ' + @base_msg;
        exec [schema_version].[add_audit_event] @proc_id = @@procid, @message = @error_message;
        throw 50000, @error_message, 1;
    end catch;

    -- becasue we passed over to this stage the step was successful and we can make the notes about completness.
    if @is_downgrade_direction = 1
    begin
        -- flip over the upgrade step completeness status relating to the @step_id.
        update [schema_version].[step]
        set [completed] = 0
        where [schema_name] = @schema_name
            and [application_name] = @application_name
            and [version] = @step_version
            and [sequence] = @step_sequence
            and [upgrade] = 1;
    end;
    else if @is_upgrade_direction = 1
    begin
        -- flip over the downgrade step completeness status relating to the @step_id.
        update [schema_version].[step]
        set [completed] = 0
        where [schema_name] = @schema_name
            and [application_name] = @application_name
            and [version] = @step_version
            and [sequence] = @step_sequence
            and [upgrade] = 0;
    end;

    -- Flipping completed flag on successfull step execution.
    update [schema_version].[step]
    set [completed] = 1
    where [id] = @step_id;

    set @msg =  N'SUCCESS: step_id=' + cast(@step_id as varchar(38)) + N' completed = 1.';
    exec [schema_version].[add_audit_event] @proc_id = @@procid, @message = @msg;

    return 0;
end
