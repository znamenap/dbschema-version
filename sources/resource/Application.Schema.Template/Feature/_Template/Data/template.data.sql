print 'Repopulating static data [template].[template] ...'
set identity_insert [template].[template] on;

merge into [template].[template] as dest using ( values
    (0, 'localsystem', 'localsystem', 'localsystem')
  , (1, 'sysDevApp01', 'Development', 'Application 1')
  , (2, 'sysDevApp02', 'Development', 'Application 2')
) as src ([id], [column1], [column2], [column3]) on dest.[column1] = src.[column1]
when matched and ([src].[column1] != [dest].[column1] or [src].[column2] != [dest].[column2] or [src].[column3] != [dest].[column3]) then
    update set [column1] = [src].[column1], [column2] = [src].[column2], [column3] = [src].[column3]
when not matched by target 
    then insert ([id], [column1], [column2], [column3]) values ([src].[id], [src].[column1], [src].[column2], [src].[column3])
when not matched by source 
    then delete
output $action as [action], '[template].[template]' as [table_name]
    , case $action when 'UPDATE' then [Inserted].[id]      when 'INSERT' then [Inserted].[id]       when 'DELETED' then null                end as [id]
    , case $action when 'UPDATE' then [Deleted].[id]       when 'INSERT' then null                  when 'DELETED' then [Deleted].[id]      end as [previous_id]
    , case $action when 'UPDATE' then [Inserted].[column1] when 'INSERT' then [Inserted].[column1]    when 'DELETED' then null              end as [column1]
    , case $action when 'UPDATE' then [Deleted].[column1]  when 'INSERT' then null                  when 'DELETED' then [Deleted].[column1] end as [previous_column1]
    , case $action when 'UPDATE' then [Inserted].[column2] when 'INSERT' then [Inserted].[column2] when 'DELETED' then null                 end as [column2]
    , case $action when 'UPDATE' then [Deleted].[column2]  when 'INSERT' then null                  when 'DELETED' then [Deleted].[column2] end as [previous_column2]
    , case $action when 'UPDATE' then [Inserted].[column3] when 'INSERT' then [Inserted].[column3] when 'DELETED' then null                 end as [column3]
    , case $action when 'UPDATE' then [Deleted].[column3]  when 'INSERT' then null                  when 'DELETED' then [Deleted].[column3] end as [previous_column3]
;

set identity_insert [template].[template] off;
