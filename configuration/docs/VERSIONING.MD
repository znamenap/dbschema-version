# Versioning

This library supports the version evidence per ApplicationName and ApplicationSchemaName. The version is the string format as the input and then calculated via weights at each position into an integer. This integer is assigned to each of the registered step in the upgrade or downgrade step and secondly persisted in table `[schema_version].[version]` together with the ApplicationName and ApplicationSchema.
This allows to track the database's schema version per Application with a given name and version.
If there are upgrade steps registered between two versions (i.e. 1.0 and 1.1) these steps gets executed and if all went well the version is set on to 1.1 in the end into the version table.

The following example registers steps between the versions 1.0 and 2.1 for the application with the 'test_app' name and using schema 'test_app_schema':
```sql
declare @upgrade_steps as [schema_version].[t_step];
insert into @upgrade_steps (
      [version] -- [schema_version].[t_version] not null
    , [sequence] -- smallint not null
    , [description] -- nvarchar(128) not null
    , [procedure] -- [sys].[sysname] not null
    )
    values
      ( 10000, 0,  'description 1.0 s0',  'procedure_10000_upgrade_step_0' )
    , ( 10000, 1,  'description 1.0 s1',  'procedure_10000_upgrade_step_1' )
    , ( 10000, 2,  'description 1.0 s2',  'procedure_10000_upgrade_step_2')
    , ( 10000, 3,  'description 1.0 s3',  'procedure_10000_upgrade_step_3')
    , ( 10000, 10, 'description 1.0 s10', 'procedure_10000_upgrade_step_10')
    , ( 10001, 0,  'description 1.1 s0',  'procedure_10001_upgrade_step_0' )
    , ( 10001, 1,  'description 1.1 s1',  'procedure_10001_upgrade_step_1' )
    , ( 10001, 2,  'description 1.1 s2',  'procedure_10001_upgrade_step_2')
    , ( 10001, 3,  'description 1.1 s3',  'procedure_10001_upgrade_step_3')
    , ( 10001, 10, 'description 1.1 s10', 'procedure_10001_upgrade_step_10')
    , ( 10002, 0,  'description 1.2 s0',  'procedure_10002_upgrade_step_0' )
    , ( 10002, 1,  'description 1.2 s1',  'procedure_10002_upgrade_step_1' )
    , ( 10002, 2,  'description 1.2 s2',  'procedure_10002_upgrade_step_2')
    , ( 10002, 3,  'description 1.2 s3',  'procedure_10002_upgrade_step_3')
    , ( 10002, 10, 'description 1.2 s10', 'procedure_10002_upgrade_step_10')
    , ( 20000, 0,  'description 2.0 s0',  'procedure_20000_upgrade_step_0' )
    , ( 20000, 1,  'description 2.0 s1',  'procedure_20000_upgrade_step_1' )
    , ( 20000, 2,  'description 2.0 s2',  'procedure_20000_upgrade_step_2')
    , ( 20000, 3,  'description 2.0 s3',  'procedure_20000_upgrade_step_3')
    , ( 20000, 10, 'description 2.0 s10', 'procedure_20000_upgrade_step_10')
    , ( 20001, 0,  'description 2.1 s0',  'procedure_20001_upgrade_step_0' )
    , ( 20001, 1,  'description 2.1 s1',  'procedure_20001_upgrade_step_1' )
    , ( 20001, 2,  'description 2.1 s2',  'procedure_20001_upgrade_step_2')
    , ( 20001, 3,  'description 2.1 s3',  'procedure_20001_upgrade_step_3')
    , ( 20001, 10, 'description 2.1 s10', 'procedure_20001_upgrade_step_10')
;
exec [schema_version].[register_upgrade_step] @schema_name = 'test_app_schema'      -- t_schema_name
                                            , @application_name = 'test_app' -- t_application_name
                                            , @step = @upgrade_steps             -- t_step
;
```

