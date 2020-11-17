create procedure [schema_version].[set_version]
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
  , @version [schema_version].[t_version]
as
begin
    if @version is null
        throw 50000, 'null argument value at @version is not expected', 1;

    if exists
    (
        select [version]
        from [schema_version].[version]
        where @application_name = [application_name]
              and [schema_name] = @schema_name
    )
    begin
        update [schema_version].[version]
        set [version] = @version
        where @application_name = [application_name]
              and [schema_name] = @schema_name;
    end;
    else
    begin
        insert [schema_version].[version]
        (
            [schema_name]
          , [application_name]
          , [version]
        )
        values
        (@schema_name, @application_name, @version);
    end;

    declare @msg as nvarchar(2048);
    set @msg = N'INFO: Setting "' + @schema_name + N'" schema''s version to "' + cast(@version as nvarchar(40))
          + N'" registered by application "' + @application_name+N'".';
    exec [schema_version].[add_audit_event] @proc_id = @@procid, @message = @msg;

    return 1;
end;
