print 'Repopulating static data [template].[group] ...'
set identity_insert [template].[group] on;

merge into [template].[group] as dest using ( values
    (0, 'system')
  , (1, 'apps')
) as src ([id], [name]) on dest.[id] = src.[id]
when matched and ([src].[name] != [dest].[name]) then
    update set [name] = [src].[name]
when not matched by target 
    then insert ([id], [name]) values ([src].[id], [src].[name])
when not matched by source 
    then delete
output $action as [action], '[template].[group]' as [table_name]
    , case $action when 'UPDATE' then [Inserted].[id]   when 'INSERT' then [Inserted].[id]   when 'DELETED' then null                 end as [id]
    , case $action when 'UPDATE' then [Deleted].[id]    when 'INSERT' then null              when 'DELETED' then [Deleted].[id]       end as [previous_id]
    , case $action when 'UPDATE' then [Inserted].[name] when 'INSERT' then [Inserted].[name] when 'DELETED' then null                 end as [name]
    , case $action when 'UPDATE' then [Deleted].[name]  when 'INSERT' then null              when 'DELETED' then [Deleted].[name]     end as [previous_name]
;

set identity_insert [template].[group] off;
