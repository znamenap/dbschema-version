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

    print 'Setting schema "' + @schema_name + '" version to "' + cast(@version as varchar(40))
          + '" registered by application "' + @application_name+'".';
    return 1;
end;
