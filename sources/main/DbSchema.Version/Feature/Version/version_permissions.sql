/*
database, ALL means BACKUP DATABASE, BACKUP LOG, CREATE DATABASE, CREATE DEFAULT, CREATE FUNCTION, CREATE PROCEDURE, CREATE RULE, CREATE TABLE, and CREATE VIEW.
scalar function, ALL means EXECUTE and REFERENCES.
table-valued function, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
stored procedure, ALL means EXECUTE.
table, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
view, ALL means DELETE, INSERT, REFERENCES, SELECT, and UPDATE.
*/

-- table-valued function: [schema_version].[get_version]
grant select, references on object::[schema_version].[get_version]
    to [schema_version_reader], [schema_version_writer], [schema_version_owner];
go

-- stored procedure: [schema_version].[parse_version]
grant execute on object::[schema_version].[parse_version]
    to [schema_version_reader], [schema_version_writer], [schema_version_owner];
go

-- stored procedure: [schema_version].[set_version]
grant execute on object::[schema_version].[set_version]
    to [schema_version_writer], [schema_version_owner];
go

-- stored procedure: [schema_version].[invoke_version_change]
grant execute on object::[schema_version].[invoke_version_change]
    to [schema_version_writer], [schema_version_owner];
go

-- table: [schema_version].[version]
grant select, references on object::[schema_version].[version]
    to [schema_version_reader], [schema_version_writer], [schema_version_owner];
go
grant delete, insert, update on object::[schema_version].[version]
    to [schema_version_writer], [schema_version_owner];
go
