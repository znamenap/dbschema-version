# Development Notes

## Other Resource Materials

- [Compare Redgate SQL Source Control and Microsoft SQL Server Data Tools](http://dlmconsultants.com/wp-content/uploads/2018/12/Redgate-vs-SSDT-3.pdf)
- Consider using in the future this tooling [MSBuild.Sdk.SqlProj](https://github.com/rr-wfm/MSBuild.Sdk.SqlProj)

## Design Notes

- Upgrade or Downgrade step is differenitated by column value Upgrade.
  If it is Upgrade = 0 it means downgrade step.

**Expected scenario:**

- A developer maintains list of records representing the steps to be registered into `[schema_version].[step]`
  per order of \<database schema name, application name and version>.
- Application developer must grant execute permission to the upgrade or downgrade step procedure to user [schema_version_writer].
- When the upgrade have to happen, the developer ought
  to insert the records into the steps table to represent desired upgrade
  or downgrade scenario(s).
- When a developer invokes `[schema_version].[invoke_version_change]` then the system
  executes necessary steps to get to the version as requested. It performs
  the stored procedures invocation in the sequence of the steps ordered by `sequence`
  column up on to the the last step with the version matching the requested version.
  Depending on the actual version and the target version determines if it performs upgrade or downgrade.

## Implementation Points

- Version parsing
- Version registry per application and schema name.
- Downgrade step registry per application and schema name.
- Upgrade step registry per application and schema name.
- Make step change invocation via procedure.
- Refactor step invocation into dedicated stored procedure.
- Added roles for reader, writer and owner.
- Added permissions per each db object.
- Added existence check for procedure of the step while registering it.
- Restructure the repo to use higher level folder for configuration stuff.
- Make auditing to who, when and what has been version changed.
- Add the script to build the giant change script in one transaction.
- Add contributor for static data deployment.
- Add contributor for invoking the schema version change.
- Consider transactionality in procedures or whether to assume external transaction or none. Transaction gets deadlocked when there is a fragment introducing a new user defined type and it gets used later on. Therefore the DBSchema.Version must be deployed at first time as the separate transaction to make the schema established and only then the application schema can be provision with this tooling.
- Make single build script for whole project to get up to the NuGet package in output.

## .NET 6 Upgrade

The goal is to convert the all liabilities to the .NET 6 platform and utilise Microsoft.SQL.Build project. Therefore, we break the compatibility with the old SSDT version based on the .NET Framework.

- [ ] Convert UpdateAssemblyInfoFile.targets to utilise the Assembly attribute from the project file. More likely should be converted to set in the default.proj file.
- [ ] Convert DbSchema.Version.Contributors project to .NET core style project using csproj and reference the assemblies from .NET6 and Microsoft.SQL.Build solution.
- [ ] Convert build project from PowerShell to msbuildproj project.
- [ ] Convert documentation folder into to msbuildproj project.
- [ ] Upgrade the solution so that it uses .NET 6 build principles.
- [ ] Upgrade the solution so that it uses central package versions.
- [ ] Split solution to three modules a) the dbschema-contributors, b) the dbschema-version and c) the dbschema-template project consuming the both.
- [ ] Update the dbschema-contributors solution project, so that it produces conventional targets to be injected into the imported SQL project, so that the NuGet package contains build folder, lib folder and tools folder.
- [ ] Update the dbschema-version solution project to consumes the contributors assembly so that it utilises the contributors features.
- [ ] Update the dbschema-template solution project consumes the both dbschema-contributors and dbschema-version so that it demonstrates the abilities of the functionality.
