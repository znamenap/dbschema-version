# Static Data

The static data represents essential part to any type of application using the enums or references to various kinds of types. Basically, these data changes sporadically only. If it needs to change then it is usually on the event of new development work or any hot-fixing. In any case you had to modify it, you have to also distribute the change to database or in the later case back to source control.

It supports transactional behaviour if it was enabled in deployment settings.

> [!WARNING]
> This contributor library version does not support validation of the code and entities in .data.sql files.
> You must ensure yourself it refers to correct table and columns.


1. It is expected from you to modify your sqlproj file and add the following property setting to enable the static data deployment. It is disabled by default. This step is required only once.
   ```xml
    <PropertyGroup>
        <DeployStaticDataEnabled>True</DeployStaticDataEnabled>
    </PropertyGroup>
    ```
    > [!NOTE]
    > It is expected you read about how to add reference to DbSchema.Version.Contributors at [Referencing](REFERENCING.MD).
    > 

2. Add a new t-sql script file and give it a name ending with .data.sql. Then set the file's Build Action to **Build Extension Contributor** via file properties.

3. It is expected you make the static data script and having the merge t-sql statement to set the static data content.
    ```sql
    print 'Repopulating static data [template].[user] ...'
    set identity_insert [template].[user] on;

    merge into [template].[user] as dest using ( values
        (0, 'LocalSystem', 'LocalSystem', 'LocalSystem')
    , (1, 'sysDevApp01', 'Development', 'Application 1')
    , (2, 'sysDevApp02', 'Development', 'Application 2')
    ) as src ([id], [login], [given_name], [surname]) on dest.[id] = src.[id]
    when matched and ([src].[login] != [dest].[login] or [src].[given_name] != [dest].[given_name] or [src].[surname] != [dest].[surname]) then
        update set [login] = [src].[login], [given_name] = [src].[given_name], [surname] = [src].[surname]
    when not matched by target 
        then insert ([id], [login], [given_name], [surname]) values ([src].[id], [src].[login], [src].[given_name], [src].[surname])
    when not matched by source 
        then delete
    output $action as [action], '[template].[user]' as [table_name]
        , case $action when 'UPDATE' then [Inserted].[id]       when 'INSERT' then [Inserted].[id]       when 'DELETED' then null                 end as [id]
        , case $action when 'UPDATE' then [Deleted].[id]        when 'INSERT' then null                  when 'DELETED' then [Deleted].[id]       end as [previous_id]
        , case $action when 'UPDATE' then [Inserted].[login]    when 'INSERT' then [Inserted].[login]    when 'DELETED' then null                 end as [login]
        , case $action when 'UPDATE' then [Deleted].[login]     when 'INSERT' then null                  when 'DELETED' then [Deleted].[login]    end as [previous_login]
        , case $action when 'UPDATE' then [Inserted].[given_name] when 'INSERT' then [Inserted].[given_name] when 'DELETED' then null                 end as [given_name]
        , case $action when 'UPDATE' then [Deleted].[given_name]  when 'INSERT' then null                  when 'DELETED' then [Deleted].[given_name] end as [previous_given_name]
        , case $action when 'UPDATE' then [Inserted].[surname]  when 'INSERT' then [Inserted].[surname]  when 'DELETED' then null                 end as [given_name]
        , case $action when 'UPDATE' then [Deleted].[surname]   when 'INSERT' then null                  when 'DELETED' then [Deleted].[surname]  end as [previous_given_name]
    ;

    set identity_insert [template].[user] off;
    ```

    The above example merge statement contains also the output statement. The output statement is not mandatory but it helps to identify the changes while running the deployment script against the database.
