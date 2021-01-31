create procedure [schema_version].[add_audit_event]
    @proc_id int = @@procid
  , @message nvarchar(2048)
as
begin
    set nocount on;
    declare @proc_name sysname;
    set @proc_name = object_name(@proc_id);
    if (xact_state()) = -1
    begin
        print '    ->' + @proc_name + '-> ' + @message + ', error message: ' + @@error_message
    end else begin
        insert into [schema_version].[audit_event] ([from], [message] )
            values ( @proc_name, @message );

        print '    ->' + @proc_name + '-> ' + @message
    end
end
