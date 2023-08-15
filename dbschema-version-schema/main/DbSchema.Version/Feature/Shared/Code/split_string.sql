﻿CREATE FUNCTION [schema_version].[split_string]
        (@pString VARCHAR(8000), @pDelimiter CHAR(1))
returns @returntable table
(
    [item_number] int not null
  , [item] varchar(8000) not null
)
 as begin
    --===== "Inline" CTE Driven "Tally Table" produces values from 0 up to 10,000...
    -- enough to cover NVARCHAR(4000)
  WITH E1(N) AS (
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                ),                          --10E+1 or 10 rows
       E2(N) AS (SELECT 1 FROM E1 a, E1 b), --10E+2 or 100 rows
       E4(N) AS (SELECT 1 FROM E2 a, E2 b), --10E+4 or 10,000 rows max
  cteTally(N) AS (--==== This provides the "base" CTE and limits the number of rows right up front
                     -- for both a performance gain and prevention of accidental "overruns"
                 SELECT TOP (ISNULL(DATALENGTH(@pString),0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E4
                ),
  cteStart(N1) AS (--==== This returns N+1 (starting position of each "element" just once for each delimiter)
                 SELECT 1 UNION ALL
                 SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@pString,t.N,1) = @pDelimiter
                ),
  cteLen(N1,L1) AS(--==== Return start and length (for use in substring)
                 SELECT s.N1,
                        ISNULL(NULLIF(CHARINDEX(@pDelimiter,@pString,s.N1),0)-s.N1,8000)
                   FROM cteStart s
                )
  --===== Do the actual split. The ISNULL/NULLIF combo handles the length for the final element when no delimiter is found.
  insert into @returntable
  select item_number = ROW_NUMBER() OVER(ORDER BY l.N1),
         item        = SUBSTRING(@pString, l.N1, l.L1)
  FROM cteLen l;
   
  return;
end;