
print 'Testing permission denied for reader to execute invoke_version_change.'
begin try
    print '  Current suser: ' + suser_name() + ', user: ' + user_name();
    execute as user = 'test_user_reader';
    print '  Current suser: ' + suser_name() + ', user: ' + user_name();
    execute [schema_version].[invoke_version_change] [dbo], 'test_app', 10000;
    revert;
    print '  Current suser: ' + suser_name() + ', user: ' + user_name();
end try
begin catch 
    revert;
    if error_message() not like '%%permission was denied on the object ''invoke_version_change''%%'
    begin
        declare @error nvarchar(1024) = concat('Expecting %%permission was denied%% exception, but received:', error_message());
        throw 50000, @error, 1;
    end
end catch
go

print 'Testing permission allowed for writer to execute invoke_version_change.'
print '  Current suser: ' + suser_name() + ', user: ' + user_name();
execute [schema_version].[invoke_version_change] [dbo], 'test_app', 10000;
execute as user = 'test_user_writer';
print '  Current suser: ' + suser_name() + ', user: ' + user_name();
execute [schema_version].[invoke_version_change] [dbo], 'test_app', 10001;
revert;
print '  Current suser: ' + suser_name() + ', user: ' + user_name();
go

print 'Testing permission allowed for owner to execute invoke_version_change.'
print '  Current suser: ' + suser_name() + ', user: ' + user_name();
execute [schema_version].[invoke_version_change] [dbo], 'test_app', 10000;
execute as user = 'test_user_owner';
print '  Current suser: ' + suser_name() + ', user: ' + user_name();
execute [schema_version].[invoke_version_change] [dbo], 'test_app', 10001;
revert;
print '  Current suser: ' + suser_name() + ', user: ' + user_name();
go

