create procedure [schema_version].[invoke_version_change]
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
  , @version [schema_version].[t_version]
as
begin
    set nocount on;

    -- which is the actual version
    declare @actual_version as [schema_version].[t_version];
    select @actual_version = [v].[version]
    from [schema_version].[get_version](@schema_name, @application_name) as [v];
    if @actual_version is null
        set @actual_version = 0;

    -- How many steps do we proceed with
    declare @step_count int;
    select @step_count = count([s].[step_id])
    from [schema_version].[get_step](@schema_name, @application_name, @actual_version, @version) as [s];

    -- Notify about empty sequence.
    if @step_count = 0 or @step_count is null
    begin
        print 'There are no change(s) detected between ' + cast(@actual_version as varchar(38)) + ' and '
              + cast(@version as varchar(38));
    end;

    -- Proceed with the step execution
    if @actual_version != @version
    begin

        declare @actual_step_id as int;
        declare @actual_step_version as [schema_version].[t_version];
        declare @actual_step_sequence as smallint;
        declare @actual_step_description as nvarchar(128);
        declare @actual_step_procedure as [sys].[sysname];
        declare @is_upgrade_direction as bit;
        declare @is_downgrade_direction as bit;

        -- determine the steps to proceed with the version change
        if @actual_version <= @version -- upgrade
            declare [actual_change_steps] cursor local forward_only read_only for
            select [s].[step_id]
                 , [s].[step_version]
                 , [s].[step_sequence]
                 , [s].[step_description]
                 , [s].[step_procedure]
                 , [s].[is_upgrade_direction]
                 , [s].[is_downgrade_direction]
            from [schema_version].[get_step](@schema_name, @application_name, @actual_version, @version) as [s]
            order by [s].[step_version], [s].[step_sequence];
        else
            declare [actual_change_steps] cursor local forward_only read_only for
            select [s].[step_id]
                 , [s].[step_version]
                 , [s].[step_sequence]
                 , [s].[step_description]
                 , [s].[step_procedure]
                 , [s].[is_upgrade_direction]
                 , [s].[is_downgrade_direction]
            from [schema_version].[get_step](@schema_name, @application_name, @actual_version, @version) as [s]
            order by [s].[step_version] desc, [s].[step_sequence] desc;

        open [actual_change_steps];
        fetch next from [actual_change_steps]
        into @actual_step_id
           , @actual_step_version
           , @actual_step_sequence
           , @actual_step_description
           , @actual_step_procedure
           , @is_upgrade_direction
           , @is_downgrade_direction
           ;
        if @@fetch_status = -1
        begin
            print 'There are no change steps registered between ' + cast(@actual_version as varchar(38)) + ' and '
                  + cast(@version as varchar(38));
        end;
        else
        begin
            while @@fetch_status = 0
            begin
                begin try
                    -- must throw error if it failed on processing.
                    execute [schema_version].[invoke_step_procedure]
                          @schema_name = @schema_name
                        , @application_name = @application_name
                        , @version = @actual_version
                        , @step_id = @actual_step_id
                        , @step_version = @actual_step_version
                        , @step_sequence = @actual_step_sequence
                        , @step_description = @actual_step_description
                        , @step_procedure = @actual_step_procedure
                        , @is_upgrade_direction = @is_upgrade_direction
                        , @is_downgrade_direction = @is_downgrade_direction
                    ;
                end try
                begin catch
                    close [actual_change_steps];
                    deallocate [actual_change_steps];
                    throw;
                end catch

                fetch next from [actual_change_steps]
                into @actual_step_id
                   , @actual_step_version
                   , @actual_step_sequence
                   , @actual_step_description
                   , @actual_step_procedure
                   , @is_upgrade_direction
                   , @is_downgrade_direction
                ;
            end;
        end;
        close [actual_change_steps];
        deallocate [actual_change_steps];
    end;

    -- set the version if the result was successfull.
    exec [schema_version].[set_version] @schema_name = @schema_name
                                      , @application_name = @application_name
                                      , @version = @version;
end;