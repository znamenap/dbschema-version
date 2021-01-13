create table [schema_version].[step]
(
    [id] int not null identity(1,1) constraint pk_schema_version_step_id primary key
    , [schema_name] [schema_version].[t_schema_name] not null
    , [application_name] [schema_version].[t_application_name] not null
    , [version] [schema_version].[t_version] not null
    , [upgrade] bit not null constraint df_schema_version_step_upgrade default ((1))
    , [sequence] smallint not null
    , [description] nvarchar(128) not null
    , [procedure] [sys].[sysname] not null
    , [completed] bit not null constraint df_schema_version_step_completed default ((0))
);
