print 'Repopulating static data [template].[user] ...'
set identity_insert [template].[user] on;

merge into [template].[user] as dest using ( values
    (0, 'localsystem', 'localsystem', 'localsystem')
  , (1, 'sysDevApp01', 'Development', 'Application 1')
  , (2, 'sysDevApp02', 'Development', 'Application 2')
) as src ([id], [login], [givename], [surname]) on dest.[id] = src.[id]
when matched and ([src].[login] != [dest].[login] or [src].[givename] != [dest].[givename] or [src].[surname] != [dest].[surname]) then
    update set [login] = [src].[login], [givename] = [src].[givename], [surname] = [src].[surname]
when not matched by target 
    then insert ([id], [login], [givename], [surname]) values ([src].[id], [src].[login], [src].[givename], [src].[surname])
when not matched by source 
    then delete
output $action as [action], '[template].[user]' as [table_name]
    , case $action when 'UPDATE' then [Inserted].[id]       when 'INSERT' then [Inserted].[id]       when 'DELETED' then null                 end as [id]
    , case $action when 'UPDATE' then [Deleted].[id]        when 'INSERT' then null                  when 'DELETED' then [Deleted].[id]       end as [previous_id]
    , case $action when 'UPDATE' then [Inserted].[login]    when 'INSERT' then [Inserted].[login]    when 'DELETED' then null                 end as [login]
    , case $action when 'UPDATE' then [Deleted].[login]     when 'INSERT' then null                  when 'DELETED' then [Deleted].[login]    end as [previous_login]
    , case $action when 'UPDATE' then [Inserted].[givename] when 'INSERT' then [Inserted].[givename] when 'DELETED' then null                 end as [givename]
    , case $action when 'UPDATE' then [Deleted].[givename]  when 'INSERT' then null                  when 'DELETED' then [Deleted].[givename] end as [previous_givename]
    , case $action when 'UPDATE' then [Inserted].[surname]  when 'INSERT' then [Inserted].[surname]  when 'DELETED' then null                 end as [givename]
    , case $action when 'UPDATE' then [Deleted].[surname]   when 'INSERT' then null                  when 'DELETED' then [Deleted].[surname]  end as [previous_givename]
;

set identity_insert [template].[user] off;
