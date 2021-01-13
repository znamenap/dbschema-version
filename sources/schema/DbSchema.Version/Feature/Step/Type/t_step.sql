create type [schema_version].[t_step] as table
(
      [version] [schema_version].[t_version] not null
    , [sequence] smallint not null
    , [description] nvarchar(128) not null
    , [procedure] [sys].[sysname] not null
);
