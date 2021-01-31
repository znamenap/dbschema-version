<#
.SYNOPSIS
    Exports the dead-locks XML from system healt event source.
.EXAMPLE
    PS> .\Export-SqlDeadLock.ps1 -Server "(localdb)\ProjectsV13" -Directory .\output\database\deadlocks
#>
[CmdLetBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Server,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Directory
)
process {
    $Query = @"
    DECLARE @LogPath NVARCHAR(255) = (SELECT CAST(SERVERPROPERTY('ErrorLogFileName') AS NVARCHAR(255)))
    declare @err_idx as int = charindex('\ERROR.LOG', @LogPath);
    if @err_idx > 0
        SET @LogPath = SUBSTRING(@LogPath, 1, @err_idx - 1)

    SELECT
        CONVERT(xml, event_data).query('/event/data/value/child::*') as deadlock,
        CONVERT(xml, event_data).value('(event[@name="xml_deadlock_report"]/@timestamp)[1]','datetime') AS ExecutionTime
    FROM sys.fn_xe_file_target_read_file(@LogPath + '\system_health*.xel', null, null, null)
    WHERE object_name like 'xml_deadlock_report'
"@

    $DBAToolsCommand = Get-Command -Name 'Invoke-DbaQuery' -Module 'dbatools' -ErrorAction SilentlyContinue
    $Results = if ($DBAToolsCommand) {
        # With dbatools module
        Invoke-DbaQuery -SqlInstance $Server -Query $Query
    } else {
        # With sqlserver module
        $SqlServerCommand = Get-Command -Name 'Invoke-Sqlcmd' -Module 'SqlServer' -ErrorAction SilentlyContinue
        if ($SqlServerCommand) {
            Invoke-Sqlcmd -ServerInstance $Server -Query $Query
        }
        else
        {
            throw "Cannot import command Invoke-Sqlcmd (from SqlServer module) or Invoke-DbaQuery (from dbatools)"
        }
    }

    $ServerName = $Server
    $ServerName = $ServerName -ireplace '\\','-'
    $ServerName = $ServerName -ireplace '\(|\)',''

    # Create a folder to save the files
    $Directory = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($Directory)
    $DirectoryItem = New-Item -Path $Directory -ItemType Directory -Force

    # Save each XML as xdl file on the filesystem
    Write-Verbose ("Observed dedlocks: {0}" -f $Results.Count)
    Add-Type -AssemblyName "System.Xml.Linq"
    $Results | Where-Object { $_ } | ForEach-Object {
        $FileName = "{0}-deadlock-{1}.xdl" -f $ServerName, ($_.ExecutionTime.ToString("yyyyMMdd-hhmmss"))
        $Path = Join-Path -Path $DirectoryItem -ChildPath $FileName
        Clear-Content -Path $Path -ErrorAction SilentlyContinue
        Write-Debug ("Deadlock: {0}" -f $_.deadlock)
        [System.Xml.Linq.XDocument]::Parse($_.deadlock).Save($Path)
        Get-Item -Path $Path
    }
}