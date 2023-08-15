/*
database, ALL means BACKUP DATABASE, BACKUP LOG, CREATE DATABASE, CREATE DEFAULT, CREATE FUNCTION, CREATE PROCEDURE, CREATE RULE, CREATE TABLE, and CREATE VIEW.
scalar function, ALL means EXECUTE and REFERENCES.
table-valued function, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
stored procedure, ALL means EXECUTE.
table, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
view, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
*/

-- table-valued function: [schema_version].[get_step]
grant select, references on object::[schema_version].[get_step]
    to [schema_version_reader], [schema_version_writer], [schema_version_owner]
        as [dbo];
go

-- stored procedure: [schema_version].[register_upgrade_step]
grant execute on object::[schema_version].[register_upgrade_step]
    to [schema_version_writer], [schema_version_owner]
        as [dbo];
go

-- stored procedure: [schema_version].[register_downgrade_step]
grant execute on object::[schema_version].[register_downgrade_step]
    to [schema_version_writer], [schema_version_owner]
        as [dbo];
go

-- stored procedure: [schema_version].[register_downgrade_step]
grant execute on object::[schema_version].[invoke_step_procedure]
    to [schema_version_writer], [schema_version_owner]
        as [dbo];
go

-- table: [schema_version].[step]
grant select, references on object::[schema_version].[step]
    to [schema_version_reader], [schema_version_writer], [schema_version_owner]
        as [dbo];
go
grant delete, insert, update on object::[schema_version].[step]
    to [schema_version_writer], [schema_version_owner]
        as [dbo];
go
