set nocount on;

delete [schema_version].[step];

delete [schema_version].[version];

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
exec [schema_version_tests].[recreate_dummy_steps] @schema = '[dbo]', @steps = @upgrade_steps;
exec [schema_version].[register_upgrade_step] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app' -- t_application_name
                                            , @step = @upgrade_steps             -- t_step
;

declare @downgrade_steps as [schema_version].[t_step];
insert into @downgrade_steps (
      [version] -- [schema_version].[t_version] not null
    , [sequence] -- smallint not null
    , [description] -- nvarchar(128) not null
    , [procedure] -- [sys].[sysname] not null
    )
    values 
      ( 10000, 0,  'description 1.0 s0',  'procedure_10000_downgrade_step_0')
    , ( 10000, 1,  'description 1.0 s1',  'procedure_10000_downgrade_step_1')
    , ( 10000, 2,  'description 1.0 s2',  'procedure_10000_downgrade_step_2')
    , ( 10000, 3,  'description 1.0 s3',  'procedure_10000_downgrade_step_3')
    , ( 10000, 10, 'description 1.0 s10', 'procedure_10000_downgrade_step_10')
    , ( 10001, 0,  'description 1.1 s0',  'procedure_10001_downgrade_step_0')
    , ( 10001, 1,  'description 1.1 s1',  'procedure_10001_downgrade_step_1')
    , ( 10001, 2,  'description 1.1 s2',  'procedure_10001_downgrade_step_2')
    , ( 10001, 3,  'description 1.1 s3',  'procedure_10001_downgrade_step_3')
    , ( 10001, 10, 'description 1.1 s10', 'procedure_10001_downgrade_step_10')
    , ( 10002, 0,  'description 1.2 s0',  'procedure_10002_downgrade_step_0')
    , ( 10002, 1,  'description 1.2 s1',  'procedure_10002_downgrade_step_1')
    , ( 10002, 2,  'description 1.2 s2',  'procedure_10002_downgrade_step_2')
    , ( 10002, 3,  'description 1.2 s3',  'procedure_10002_downgrade_step_3')
    , ( 10002, 10, 'description 1.2 s10', 'procedure_10002_downgrade_step_10')
    , ( 20000, 0,  'description 2.0 s0',  'procedure_20000_downgrade_step_0')
    , ( 20000, 1,  'description 2.0 s1',  'procedure_20000_downgrade_step_1')
    , ( 20000, 2,  'description 2.0 s2',  'procedure_20000_downgrade_step_2')
    , ( 20000, 3,  'description 2.0 s3',  'procedure_20000_downgrade_step_3')
    , ( 20000, 10, 'description 2.0 s10', 'procedure_20000_downgrade_step_10')
    , ( 20001, 0,  'description 2.1 s0',  'procedure_20001_downgrade_step_0')
    , ( 20001, 1,  'description 2.1 s1',  'procedure_20001_downgrade_step_1')
    , ( 20001, 2,  'description 2.1 s2',  'procedure_20001_downgrade_step_2')
    , ( 20001, 3,  'description 2.1 s3',  'procedure_20001_downgrade_step_3')
    , ( 20001, 10, 'description 2.1 s10', 'procedure_20001_downgrade_step_10')
;
exec [schema_version_tests].[recreate_dummy_steps] @schema = '[dbo]', @steps = @downgrade_steps;
exec [schema_version].[register_downgrade_step] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app' -- t_application_name
                                            , @step = @downgrade_steps             -- t_step
;

print 'Testing upgrade suequence from version 0 to 2.0';
declare @version_number [schema_version].[t_version];
exec [schema_version].[parse_version] @version_text = N'2.0'                      -- nvarchar(128)
                                    , @version_number = @version_number output -- t_version
;

exec [schema_version].[invoke_version_change] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app'-- t_application_name
                                            , @version = @version_number          -- t_version
;

print 'Testing downgrade suequence from version 2.0 to 1.1';
exec [schema_version].[parse_version] @version_text = N'1.1'                      -- nvarchar(128)
                                    , @version_number = @version_number output -- t_version
;

exec [schema_version].[invoke_version_change] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app'-- t_application_name
                                            , @version = @version_number          -- t_version
;

print 'Testing upgrade suequence from version 1.1 to 1.2';
exec [schema_version].[parse_version] @version_text = N'1.2'                      -- nvarchar(128)
                                    , @version_number = @version_number output -- t_version
;

exec [schema_version].[invoke_version_change] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app'-- t_application_name
                                            , @version = @version_number          -- t_version
;

print 'Testing upgrade suequence from version 1.2 to 1.2';
exec [schema_version].[parse_version] @version_text = N'1.2'                      -- nvarchar(128)
                                    , @version_number = @version_number output -- t_version
;

exec [schema_version].[invoke_version_change] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app'-- t_application_name
                                            , @version = @version_number          -- t_version
;


print 'Testing upgrade suequence from version 1.1 to 1.3';
exec [schema_version].[parse_version] @version_text = N'1.3'                      -- nvarchar(128)
                                    , @version_number = @version_number output -- t_version
;

exec [schema_version].[invoke_version_change] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app'-- t_application_name
                                            , @version = @version_number          -- t_version
;

print 'Testing upgrade suequence from version 1.3 to 1.0';
exec [schema_version].[parse_version] @version_text = N'1.0'                      -- nvarchar(128)
                                    , @version_number = @version_number output -- t_version
;

exec [schema_version].[invoke_version_change] @schema_name = [dbo]      -- t_schema_name
                                            , @application_name = 'test_app'-- t_application_name
                                            , @version = @version_number          -- t_version
;
