create function [schema_version].[get_version]
(
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
)
returns @returntable table
(
    [schema_name] [schema_version].[t_schema_name] not null
  , [application_name] [schema_version].[t_application_name] not null
  , [version] [schema_version].[t_version] not null
)
as
begin
    insert @returntable
        select [schema_name], [application_name], [version] from [schema_version].[version] with (nolock)
            where @application_name = [application_name] and [schema_name] = @schema_name;
    return;
end;
