# Deployment

The process of deployment is simple as same as the any other .dacpac. You can use SQLPackage.exe or Visual Studio to render the script and deploy the script or directly deploy to the target database. Nevertheless, you must deploy it separately to the changes from your project's .dapac. This is because of the SQL Server limitation leading to a deadlock. There is a lock on custom user type in that moment. Only then after you deployed DbSchema.Version.dacpac, you can deploy your project's .dacpac.

## Using SQLPackage.exe
Using SQLPackage.exe has benefit over other deployments in respect of it can directly deploy into the target database. However, using SQLCmd.exe to deploy to target database might not be available at the deployment configuration.

## Using Invoke-DeployDacPac.ps1
Using Invoke-DeployDacPac.ps1 has its pros and cons. It requires both tools SQLPackage.exe and SQLCmd.exe to be available on the deployment configuration. However, it has a benefit of the sequencing and discovery of the both tools without the need to specify the paths to the tools.

# Target Database

- The target database will always have the new schema added `[schema_version]`. This name is not configurable and and it is fixed.
- There will be three roles presented:
1. `[schema_version].[schema_version_owner]` - it can do whatever in the schema in terms of the DML.
2. `[schema_version].[schema_version_writer]` - it can do the step registration and invocation.
3. `[schema_version].[schema_version_reader]` - it can perform only the reads from the tables.

