/*
Post-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/

-- TODO: Uncomment following line after Microsoft.Build.Sql fixed behaviour
-- :r ./Feature/Step/test_register_upgrade_step.sql

-- TODO: Uncomment following line after Microsoft.Build.Sql fixed behaviour
-- :r ./Feature/Step/test_register_downgrade_step.sql

-- TODO: Uncomment following line after Microsoft.Build.Sql fixed behaviour
-- :r ./Feature/Version/test_parse_version.sql

-- :r ./Feature/Version/test_invoke_version_change.sql
