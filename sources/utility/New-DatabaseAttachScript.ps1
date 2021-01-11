<#
.SYNOPSIS
    Generates SQL statements to restore databases within the connected LocalDB instances.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [regex] $Pattern = '.*'
)
process {

    & SqlLocalDB.exe info | Where-Object { $_ -imatch $Pattern } | ForEach-Object{
        Write-Verbose "Processing  (localdb)\$_"
        & SqlLocalDB.exe start $_
        & SQLCmd.exe -S "(localdb)\$_" -d master -Q @"
with dbs as (
  SELECT
    db.name AS DBName,
    (select mf.Physical_Name FROM sys.master_files mf where mf.type_desc = 'ROWS' and db.database_id = mf.database_id ) as DataFile,
    (select mf.Physical_Name FROM sys.master_files mf where mf.type_desc = 'LOG' and db.database_id = mf.database_id ) as LogFile
  FROM sys.databases db
    where db.database_id > 4
)
select 'CREATE DATABASE [' + dbs.DBName + '] ON (FILENAME = ''' + dbs.DataFile + '''), (FILENAME = ''' + dbs.LogFile + ''') FOR ATTACH;'
from dbs
go
"@
    } | Where-Object { $_ -imatch "^CREATE DATABASE" } | Set-Content -Path $Path -Encoding utf8

    Get-Item -Path $Path

}
