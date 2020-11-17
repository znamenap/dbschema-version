create table [schema_version].[audit_event]
(
      [id] int not null identity(0, 1)
        constraint [pk_schema_version_audit_event_id] primary key
    , [session_id] smallint not null
        constraint [df_schema_version_audit_event_session_id] default @@spid
    , [when] datetime not null
        constraint [df_schema_version_audit_event_when] default getutcdate()
    , [user_login] nvarchar(128) not null
        constraint [df_schema_version_audit_event_user_login] default system_user
    , [user_identity] nvarchar(128) not null
        constraint [df_schema_version_audit_event_user_identity] default current_user
    , [user_session] nvarchar(128) not null
        constraint [df_schema_version_audit_event_user_session] default session_user
    , [from] sysname not null
    , [message] nvarchar(2048) not null
);
