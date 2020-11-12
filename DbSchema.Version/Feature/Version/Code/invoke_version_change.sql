create procedure [schema_version].[invoke_version_change]
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
  , @version [schema_version].[t_version]
as
begin
    set nocount on;

    -- determine the change direction: upgrade or downgrade
    declare @actual_version as [schema_version].[t_version];
    select @actual_version = [v].[version]
    from [schema_version].[get_version](@schema_name, @application_name) as [v];
    if @actual_version is null
        set @actual_version = 0;

    declare @is_upgrade_direction as bit;
    declare @is_downgrade_direction as bit;
    if @actual_version = @version
    begin
        set @is_upgrade_direction = 0;
        set @is_downgrade_direction = 0;
    end;
    else if @actual_version >= @version
    begin
        set @is_upgrade_direction = 0;
        set @is_downgrade_direction = 1;
    end;
    else if @actual_version <= @version
    begin
        set @is_upgrade_direction = 1;
        set @is_downgrade_direction = 0;
    end;

    -- build up the sequence of steps to proceed with
    if @is_upgrade_direction = 1
    begin
        declare [actual_change_steps] cursor local forward_only dynamic for
        select [s].[id]
             , [s].[version]
             , [s].[sequence]
             , [s].[description]
             , [s].[procedure]
        from [schema_version].[step] as [s]
        where [s].[application_name] = @application_name
              and [s].[schema_name] = @schema_name
              and [s].[application_name] = @application_name
              and [s].[upgrade] = 1 -- only upgrade steps
              and [s].[completed] = 0 -- only non completed steps
              and @actual_version < [s].[version]
              and @version >= [s].[version]
        order by [s].[version]
               , [s].[sequence];
    end;
    else if @is_downgrade_direction = 1
    begin
        declare [actual_change_steps] cursor local forward_only dynamic for
        select [s].[id]
             , [s].[version]
             , [s].[sequence]
             , [s].[description]
             , [s].[procedure]
        from [schema_version].[step] as [s]
        where [s].[application_name] = @application_name
              and [s].[schema_name] = @schema_name
              and [s].[application_name] = @application_name
              and [s].[upgrade] = 0 -- only downgrade steps
              and [s].[completed] = 0 -- only non completed steps
              and [s].[version] <= @actual_version
              and [s].[version] > @version
        order by [s].[version] desc
               , [s].[sequence] desc;
    end;
    else
    begin
        print 'There are no change(s) detected between ' + cast(@actual_version as varchar(38)) + ' and '
              + cast(@version as varchar(38));
    end;

    -- proceed with the steps
    if @actual_version != @version
    begin
        declare @actual_step_id as int;
        declare @actual_step_version as [schema_version].[t_version];
        declare @actual_step_sequence as smallint;
        declare @actual_step_description as nvarchar(128);
        declare @actual_step_procedure as [sys].[sysname];

        open [actual_change_steps];
        fetch next from [actual_change_steps]
        into @actual_step_id
           , @actual_step_version
           , @actual_step_sequence
           , @actual_step_description
           , @actual_step_procedure;
        if @@fetch_status = -1
        begin
            print 'There are no change steps registered between ' + cast(@actual_version as varchar(38)) + ' and '
                  + cast(@version as varchar(38));
        end;
        else
        begin
            while @@fetch_status = 0
            begin
                declare @actual_report_message_base nvarchar(2048)
                    = '(' + cast(@actual_step_version as varchar(38)) + ', step ' + cast(@actual_step_sequence as varchar(38))
                      + ') via procedure ' + @actual_step_procedure + '()';
                print 'Executing: ' + @actual_report_message_base + ', "' + @actual_step_description + '"';

                begin try

                    -- TODO: Refactor execution & step state management into stored proc
                    -- TODO executing the procedure
                    -- exec [sys].[sp_executesql] @sql = @actual_step_procedure;
                    -- evaluate return value and if it is NULL or nought then assume successfull execution.
                    -- Flipping completed flag on successfull step execution.
                    update [schema_version].[step]
                    set [completed] = 1
                    where [id] = @actual_step_id;
                    if @is_downgrade_direction = 1
                    begin
                        -- flip over the upgrade step completeness status.
                        update [schema_version].[step]
                        set [completed] = 0
                        where [schema_name] = @schema_name
                            and [application_name] = @application_name
                            and [version] = @actual_step_version
                            and [sequence] = @actual_step_sequence
                            and [upgrade] = 1;
                    end;
                    else if @is_upgrade_direction = 1
                    begin
                        -- flip over the downgrade step completeness status.
                        update [schema_version].[step]
                        set [completed] = 0
                        where [schema_name] = @schema_name
                            and [application_name] = @application_name
                            and [version] = @actual_step_version
                            and [sequence] = @actual_step_sequence
                            and [upgrade] = 0;
                    end;

                end try
                begin catch
                    close [actual_change_steps];
                    deallocate [actual_change_steps];
                    -- Return the error information.
                    declare @error_message varchar(2048)
                        = 'Error while executing step: "' + @actual_report_message_base + '". Error (severity='
                          + cast(error_severity() as varchar(256)) + '): ' + error_message();
                    throw 50000, @error_message, 1;
                end catch;

                fetch next from [actual_change_steps]
                into @actual_step_id
                   , @actual_step_version
                   , @actual_step_sequence
                   , @actual_step_description
                   , @actual_step_procedure;
            end;
        end;
        close [actual_change_steps];
        deallocate [actual_change_steps];
    end;

    -- set the version if the result was successfull.
    -- TODO:
    exec [schema_version].[set_version] @schema_name = @schema_name
                                      , @application_name = @application_name
                                      , @version = @version;
end;