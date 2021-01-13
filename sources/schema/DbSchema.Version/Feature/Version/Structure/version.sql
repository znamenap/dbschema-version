create table [schema_version].[version]
(
    [schema_name] [schema_version].[t_schema_name] not null
  , [application_name] [schema_version].[t_application_name] not null
  , [version] [schema_version].[t_version] not null
  , constraint uq_schema_version_schema_name_application_name_version
        unique clustered ([schema_name], [application_name], [version])
);
