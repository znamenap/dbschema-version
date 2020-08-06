create procedure [schema_version].[set_version]
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
  , @version [schema_version].[t_version] 
as
begin
    if exists (
        select [version] from [schema_version].[version] 
            where @application_name = [application_name] and [schema_name] = @schema_name
        )
    begin
        update [schema_version].[version] set [version] = @version
            where @application_name = [application_name] and [schema_name] = @schema_name;
    end
    else
    begin
        insert [schema_version].[version] ([schema_name], [application_name], [version])
            values (@schema_name, @application_name, @version);
    end

    return 1;
end;
