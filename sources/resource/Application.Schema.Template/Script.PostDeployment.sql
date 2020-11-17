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

print N'Starting update'; --<< do not change me


-- ======================================
-- == BEGIN: Static data repopulation. ==
-- ======================================
print 'Repopulating static data according to database schema source dafinition.'

:r .\Feature\_Template\Data\template.data.sql
go
if @@error <> 0 and @@trancount > 0 begin rollback; end
if @@trancount = 0 begin insert into #tmperrors(error) values (1); begin transaction; end
go

:r .\Feature\User\Data\system_users.data.sql
go
if @@error <> 0 and @@trancount > 0 begin rollback; end
if @@trancount = 0 begin insert into #tmperrors(error) values (1); begin transaction; end
go

:r .\Feature\Group\Data\system_groups.data.sql
go
if @@error <> 0 and @@trancount > 0 begin rollback; end
if @@trancount = 0 begin insert into #tmperrors(error) values (1); begin transaction; end
go

print 'Repopulating static data according to database schema source dafinition .... completed.'
-- ======================================
-- == END: Static data repopulation. ==
-- ======================================

-- =========================================
-- == BEGIN: Post schema migration steps. ==
-- =========================================
print 'Transaction count: ' + cast(@@trancount as varchar(10))
begin try
    if ($(AppVersion) is not null)
    begin
        set nocount on; 
        declare @result as int = -1;
        exec @result = [schema_version].[invoke_version_change]
              @schema_name = 'template'
            , @application_name = $(AppName)
            , @version = $(AppVersion)
        if (@@error <> 0 or @result < 0) and @@trancount > 0
        begin
            print 'ERROR: invoke_version_change failed. Cause: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ')';
            rollback transaction;
        end
    end
end try
begin catch
    print 'ERROR: invoke_version_change failed. Cause: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ')';
    rollback transaction;
end catch
if @@trancount = 0 begin insert into #tmperrors(error) values (1); end;
GO
-- =======================================
-- == END: Post schema migration steps. ==
-- =======================================

------------------------------------------
-- FOOTER: Keep this as the last block
------------------------------------------
if exists (select * from #tmperrors) begin
    print 'Errors dettected, rolling the transaction back.';
    declare @error_message nvarchar(2048) = 'ERROR: The database update failed. Cause: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ')';
    print @error_message;
    drop table #tmperrors;
    throw 51000, @error_message, 1;
end;
GO

if @@trancount > 0 
begin
    begin try
        drop table #tmperrors;
        print N'Comitting the transaction.';
        commit transaction;
        print 'The database update succeedded.';
    end try
    begin catch
        declare @error_message nvarchar(2048) = 'ERROR: The database update failed. Cause: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ')';
        print @error_message;
        throw 51000, @error_message, 1;
    end catch
end
GO
