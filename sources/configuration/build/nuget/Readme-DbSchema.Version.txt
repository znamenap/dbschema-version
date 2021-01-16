
DbSchema.Version
================

This is a package of SSDT contributors, MSBuild targets and PowerShell scripts
that helps you to maintain, build and deploy the Hybrid model of SQL Project.
- It supports deployment of static data within the main transaction.
- It supports invoking stored procedures within the main transaction either due to upgrade or downgrade
- It supports tracking version per application and schema.
- It supports dumping the deployment plan into an XML for further analysis.

INSTALLATION:
1. Add NuGet reference into your main .NET application (not SQL Project becasue it is not supported).
2. Unload your SQL Project
3. Edit your SQL Project
4. Just after the last <Import Project="...SSDT..." /> statement of the SSDT targets you add a new <Import Project="..." />
   statement that targets the file from this package:
   ..\packages\DBSchema.Version.x.y.z\build\DbSchema.Version.Contributors.targets
5. Save the SQL Project.
6. Reload the SQL Project.
7. Build your first SQL Project.
8. Add database reference, select Application Tier, select DacPac from the package.
9. Select option to choose the same database.
10. Confirm adding reference to DBSchema.Version.
11. Build your first SQL Project.
12. Read more on documentation at below location.

DOCUMENTATION:
Find more in ..\packages\DBSchema.Version.x.y.z\docs\
REFERENCING.MD - how to enable certain features of contributors.
STATIC-DATA.MD - how to prepare, set up, build and deploy static data.
 VERSIONING.MD - how to keep the schema version per application.
UP-AND-DOWN.MD - how to author and cope with certain upgrade or downgrade scenarios.
 DEPLOYMENT.MD - how to deploy hybrid SQL changes.
