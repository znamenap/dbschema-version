create procedure [schema_version].[register_downgrade_step]
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
  , @step [schema_version].[t_step] readonly
as
begin
    set nocount on;
    begin try
        if @schema_name is null throw 50000, 'null argument value at @schema_name is not expected', 1;
        if @application_name is null throw 50000, 'null argument value at @application_name is not expected', 1;
        if not exists(select top(1) [version] from @step) throw 50000, 'null argument value at @step is not expected', 1;

        -- Check if the procedure step exists
        declare @missing_procedure_name sysname;
        select top(1) @missing_procedure_name = @schema_name+'.'+s.[procedure]
            from @step as [s] where object_id(@schema_name+'.'+s.[procedure]) is null
        if @missing_procedure_name is not null
        begin
            declare @err_missing_procedure_name varchar(512) =
                'specified procedure ' + @missing_procedure_name + ' does not exists in the schema';
            throw 50000, @err_missing_procedure_name, 1;
        end

        insert into [schema_version].[step]
        (
            [schema_name]
            , [application_name]
            , [version]
            , [upgrade]
            , [sequence]
            , [description]
            , [procedure]
            , [completed]
        )
        select -- 0    -- id - int
            @schema_name -- schema_name - t_schema_name
            , @application_name -- application_name - t_application_name
            , [s].[version] -- version - t_version
            , 0 as [upgrade] -- upgrade - bit
            , [s].[sequence]    -- sequence - smallint
            , [s].[description]  -- description - nvarchar(128)
            , [s].[procedure] -- procedure - sysname
            , 0 as [completed] -- completed - bit
        from @step as s;

    end try
    begin catch
        -- Return the error information.
        declare @error_message  nvarchar(2048) = concat(
            'Error while registering downgrade step in ', error_procedure(), ' for "', 
            @application_name, '" application within [', @schema_name, '] schema. Error (severity=', 
            error_severity(), '): ' , error_message());
        exec [schema_version].[add_audit_event] @proc_id = @@procid, @message = @error_message;
        throw 50000, @error_message, 1;
    end catch;
end;