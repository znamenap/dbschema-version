/*
database, ALL means BACKUP DATABASE, BACKUP LOG, CREATE DATABASE, CREATE DEFAULT, CREATE FUNCTION, CREATE PROCEDURE, CREATE RULE, CREATE TABLE, and CREATE VIEW.
scalar function, ALL means EXECUTE and REFERENCES.
table-valued function, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
stored procedure, ALL means EXECUTE.
table, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
view, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
*/

-- stored procedure: [schema_version].[add_audit_event]
grant execute on object::[schema_version].[add_audit_event]
    to [schema_version_writer], [schema_version_owner]
        as [dbo];
go

-- table: [schema_version].[audit_event]
grant select, references on object::[schema_version].[audit_event]
    to [schema_version_reader], [schema_version_writer], [schema_version_owner]
        as [dbo];
go
grant delete, insert, update on object::[schema_version].[audit_event]
    to [schema_version_writer], [schema_version_owner]
        as [dbo];
go
