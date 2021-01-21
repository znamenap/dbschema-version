# DbSchema.Version and SSDT Contributors

# Overview

This contributors library and DacPac schema are targetting MSSQL database deployments and development phases. It's approach is a bit specific. It combines features of the State and Change based development models. So you might think of it, it's kind of Hybrid model into some extent only. You can add features to your SQLProject to support:
- injecting [Static Data](docs/STATIC-DATA.MD) deployment into the main script within the main transaction if available,
- registering ApplicationName, ApplicationVersion per ApplicationSchema as versioned entity as per [Versioning](docs/VERSIONING.MD),
- registering migration steps as stored procedures as per the registered steps of the given step sequence, ApplicationName, ApplicationVersion and ApplicationSchema.
- invoking the migration steps as per the registered sequence in order to migrate database schema from the actual version to the requested version as per the deployment parameter.
- invoking the migration steps in the [Upgrade and Downgrade Process](docs/UP-AND-DOWN.MD) scenario.
- integrating the above changes into the main transaction if it was available.

This library does not require you to install the contributors into the Program Files folder, so you don't to perform any local development setup apart of to make available SSDT extensions via Visual Studio 2019 Installer (Data Payload) or via MS SQL Management Studio. You just need to reference the NuGet package and edit project files. There are more details in [Referencing](docs/REFERENCING.MD) description that advise you how to make the reference into your development environment.

It still preserves the standard deployment model with the single and dependent .dacpac from your projects. This library includes all that's necessary in the .dacpac. You can read more details how to proceed with [Deployment](docs/DEPLOYMENT.MD).

# Configuring Contributors

The contributors available with this library are configurable via MSBuild properties. You can configure them by setting the relevant properties via the PropertyGroup statements in your MSBuild files or via parameters at MSBuild command line. You set the properties before the import statement added as part the [Referencing](docs/REFERENCING.MD) process.

## Enabling Static Data Contributor

The [Static Data](docs/STATIC-DATA.MD) Contributor is configured via following property:
- **DeployStaticDataEnabled** - set this property to `true` to enable this feature. This property value defaults to `false` and thus the feature is disabled.
- and setting every desired file `*.data.sql` to be seen as the static data as like this example in the .sqlproj. It is possible to set it via properties of the file. 
```xml
 <DeploymentExtensionConfiguration Include="Feature\User\Data\system_users.data.sql" />
```

## Enabling Schema Version Deployment Contributor

The [Upgrade and Downgrade Process](docs/UP-AND-DOWN.MD) Contributor is configured via following property:
- **DeploySchemaVersionEnabled** - set this property to `true` to enable this feature. This property value defaults to `false` and thus the features is disabled.
- Add a static data like file `*.data.sql` where you can perform the upgrade and downgrade steps to be performed during the deployment. Plus, the similar for the reverse steps to perform downgrades. 
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
    , ( 10001, 0,  'description 1.1 s0',  'procedure_10001_upgrade_step_0' )
    , ( 10001, 1,  'description 1.1 s1',  'procedure_10001_upgrade_step_1' )
    , ( 10001, 2,  'description 1.1 s2',  'procedure_10001_upgrade_step_2')
;
exec [schema_version].[register_upgrade_step] @schema_name = 'test_app_schema'      -- t_schema_name
                                            , @application_name = 'test_app' -- t_application_name
                                            , @step = @upgrade_steps             -- t_step
;
```

## Enabling Restartable Script Contributor

This contributor is one of the examples provided by Microsoft example contributors. This contributor is not compatible with Schema Version Contributor. This contributor modifies a deployment plan by adding if statements to the existing batches in order to make a deployment script able to be rerun to completion if an error is encountered during execution.
This contributor is configured via following property:
- **RestartableScriptEnabled** - set this property to `true` to enable this feature. This property value defaults to `false` and thus the feature is disabled.

## Enabling Update Report Contributor

This contributor generates a report detailing the steps in the deployment plan. This is the contributor built from the SSDT examples from (documentation site)[https://docs.microsoft.com/en-us/sql/ssdt/walkthrough-extend-database-project-deployment-to-analyze-the-deployment-plan]. You can configure this contributor via properties:
- **UpdateReportEnabled** - set this property to `true` to enable this feature. This property value defaults to `false` and thus the feature is disabled.
- **DbSchema.Version.Contributors.UpdateReport.FileName** - this property value defaults to the project name via `$(Name)` property.
- **DbSchema.Version.Contributors.UpdateReport.OutDir** - this property defaults to the project output directory via `$(OutputPath)` property.

## Enabling Model Statistics Contributor

This contributor produces an XML file with the database model statistics. This is the contributor built from the SSDT examples from (documentation site)[https://docs.microsoft.com/en-us/sql/ssdt/walkthrough-extend-database-project-build-to-generate-model-statistics].You can configure this contributor via property:
- **ModelStatisticsEnabled** - set this property to true to enable this feature. This property value defaults to false and thus the feature is disabled by default.
- **DbSchema.Version.Contributors.ModelStatistics.FileName** - set this property value to set the produced statistics file name. It defaults to `$(Name).ModelStatistics.xml`.
- **DbSchema.Version.Contributors.ModelStatistics.OutDir** - set this property value to set the folder where to put the statistics file. It defaults to `$(OutputPath)`
- **DbSchema.Version.Contributors.ModelStatistics.SortModelStatisticsBy** - set this property value to one `none` or `name` or `value` in order to sort the model statistics by the specified input. It defaults to `none`. 

# Changes

## Version 1.0

- Initial version including the basic features and contributors.
