create procedure [schema_version].[parse_version] 
      @version_text as nvarchar(128)
    , @weight_base as [schema_version].[t_version] = 10000
    , @version_number as [schema_version].[t_version] output
as
begin
    set nocount on;
    begin try
        if @version_text is null
            throw 50000, 'null argument in @version_text is not expected', 1;

        select @version_number = sum(i.[weight])
            from (
                select 
                    -- [split].[value]
                    -- , row_number() over (order by (select 1)) as [position]
                    -- , count(value) over (order by (select 1)) as [count]
                    -- , (count(value) over (order by (select 1))) - (row_number() over (order by (select 1))) as [reverse_index]
                    -- , power(1000, ((count(value) over (order by (select 1))) - (row_number() over (order by (select 1))))) as [weight_base]
                    (cast([split].[item] as decimal)*power(@weight_base, ((count([split].[item]) over (order by (select 1))) - (row_number() over (order by (select 1)))))) as [weight]
                from schema_version.split_string(@version_text,'.') as [split]
            ) as i
    end try
    begin catch
        -- Return the error information.
        declare @error_message nvarchar(2048)
            = concat('Error while parsing version text "',@version_text,'". Error (severity=', error_severity(), '): ', error_message());
        throw 50000, @error_message, 1;
    end catch;
end;

