create function [schema_version].[get_step]
(
    @schema_name [schema_version].[t_schema_name]
  , @application_name [schema_version].[t_application_name]
  , @from_version [schema_version].[t_version]
  , @to_version [schema_version].[t_version]
)
returns @returntable table
(
      [step_id] int not null
    , [step_version] [schema_version].[t_version] not null
    , [step_sequence] smallint not null
    , [step_description] nvarchar(128)
    , [step_procedure] [sys].[sysname] not null
    , [is_upgrade_direction] bit not null
    , [is_downgrade_direction] bit not null
)
as
begin
    declare @is_upgrade_direction as bit;
    declare @is_downgrade_direction as bit;
    if @from_version is null or @to_version is null
    begin
        set @is_upgrade_direction = 0;
        set @is_downgrade_direction = 0;
    end;
    else if @from_version >= @to_version
    begin
        set @is_upgrade_direction = 0;
        set @is_downgrade_direction = 1;
    end;
    else if @from_version <= @to_version
    begin
        set @is_upgrade_direction = 1;
        set @is_downgrade_direction = 0;
    end;

    -- build up the sequence of steps to proceed with
    if @is_upgrade_direction = 1
    begin
        insert @returntable
        select [s].[id]
             , [s].[version]
             , [s].[sequence]
             , [s].[description]
             , [s].[procedure]
             , @is_upgrade_direction as [is_upgrade_direction]
             , @is_downgrade_direction as [is_downgrade_direction]
        from [schema_version].[step] as [s] with (nolock)
        where [s].[application_name] = @application_name
              and [s].[schema_name] = @schema_name
              and [s].[application_name] = @application_name
              and [s].[upgrade] = 1 -- only upgrade steps
              and [s].[completed] = 0 -- only non completed steps
              and @from_version < [s].[version]
              and @to_version >= [s].[version]
        ;
    end;
    else if @is_downgrade_direction = 1
    begin
        insert @returntable
        select [s].[id]
             , [s].[version]
             , [s].[sequence]
             , [s].[description]
             , [s].[procedure]
             , @is_upgrade_direction as [is_upgrade_direction]
             , @is_downgrade_direction as [is_downgrade_direction]
        from [schema_version].[step] as [s] with (nolock)
        where [s].[application_name] = @application_name
              and [s].[schema_name] = @schema_name
              and [s].[application_name] = @application_name
              and [s].[upgrade] = 0 -- only downgrade steps
              and [s].[completed] = 0 -- only non completed steps
              and [s].[version] <= @from_version
              and [s].[version] > @to_version
        ;
    end;

    return;
end;
go
