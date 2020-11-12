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
    declare @report_message_base nvarchar(2048)
        = '(' + cast(@step_version as varchar(38)) + ', step ' + cast(@step_sequence as varchar(38))
            + ') via procedure ' + @step_procedure + '()';
    print 'Executing: ' + @report_message_base + ', "' + @step_description + '"';

    begin try
        exec [sys].[sp_executesql] @sql = @step_procedure;
    end try
    begin catch
        declare @error_message varchar(2048)
            = 'Error while executing step: "' + @report_message_base + '". Error (severity='
                + cast(error_severity() as varchar(256)) + '): ' + error_message();
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

    return 0;
end
