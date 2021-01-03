[CmdletBinding()]
param(
    [Parameter()]
    [string] $DeployProfile,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Server,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Database,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $AppName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $AppVersion,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [switch] $Deploy,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [hashtable] $Property = @{},

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [hashtable] $Variable = @{},

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]] $ArgumentList,

    [Parameter()]
    [string] $SqlPackageExePath,

    [Parameter()]
    [string] $SqlCmdExePath,

    [Parameter()]
    [ValidateSet("Script", "Deploy")]
    [string] $Action = "Script",

    [Parameter()]
    [switch] $JoinTransaction
)
begin {
    $ErrorActionPreference = 'Stop'
    function Join-Transactions {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string] $Path
        )
        process {
            # The SqlPackage.exe generates at least one transaction
            # and we want to join it with our pre and post updates, so in the end
            # there is just one transaction at all.
            Write-Verbose "Joining transactions in SQL script."
            $ControlStart = $false
            $ControlEnd = $false
            (Get-Content -Path $Path) | ForEach-Object {
                if (-not $ControlStart -and -not $ControlEnd -and ($_.Equals("IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION"))) {
                    $ControlStart = $true
                    $ControlEnd = $false
                }
                if ($ControlStart -and -not $ControlEnd -and ($_.Equals("print N'Starting update'; --<< do not change me"))) {
                    $ControlStart = $false
                    $ControlEnd = $true
                }
                Write-Output $_
            } | Where-Object { -not $ControlStart } | Set-Content -Path $Path -Encoding utf8
        }
    }
    function Get-LatesExeVersionPath {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string] $ExeName,

            [Parameter()]
            [string] $Path,

            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string[]] $Location
        )
        process {
            $Path = if ($Path) {
                $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
            }
            else {
                $Location | ForEach-Object { Write-Debug "Observing: $_\$ExeName"; Write-Output "$_\$ExeName" } |
                Where-Object { Test-Path -Path $_ } |
                Get-Item -ErrorAction SilentlyContinue |
                Sort-Object -Property VersionInfo -Descending |
                ForEach-Object { Write-Debug ("Observed: {0}({1}): {2}" -f $_.Name, $_.VersionInfo.FileVersion, $_.FullName); $_ } |
                Select-Object -First 1 -ExpandProperty FullName
            }
            if (-not $Path -or (-not (Test-Path -Path $Path))) {
                throw "Cannot determine $Path on the path."
            }

            $Item = Get-Item -Path $Path
            Write-Verbose ("{0}({1}): {2}" -f $Item.Name, $Item.VersionInfo.FileVersion, $Path)
            Write-Output $Item
        }
    }

    $SqlPackageExePath = Get-LatesExeVersionPath -ExeName "SqlPackage.exe" -Path $SqlPackageExePath -Location @( "$PSScriptRoot", "$PSScriptRoot\bin",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio*\*\*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC",
        "${env:ProgramFiles}\Microsoft Visual Studio*\*\*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC",
        "${env:ProgramFiles}\Microsoft SQL Server\*\DAC\bin",
        $env:Path -split ';'
    )

    if ($Deploy.IsPresent) {
        $SqlCmdExePath = Get-LatesExeVersionPath -ExeName "SqlCmd.exe" -Path $SqlCmdExePath -Location @( "$PSScriptRoot", "$PSScriptRoot\bin",
            "${env:ProgramFiles}\Microsoft SQL Server\*\Tools\Binn",
            "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn",
            "${env:ProgramFiles(x86)}\Microsoft SQL Server\*\Tools\Binn",
            "${env:ProgramFiles(x86)}\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn",
            $env:Path -split ';'
        )
    }

}
process {
    $Path = Get-Item -Path ($PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path))
    $DeployProfile = if ($DeployProfile) { Get-Item -Path ($PSCmdlet.GetUnresolvedProviderPathFromPSPath($DeployProfile)) }
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmm"
    $DacPacDir, $DacPacName = Split-Path -Path $Path
    $ServerName = $Server.Replace('(','').Replace(')','').Replace('\', '_').Replace('/', '_')
    $PathDeployId = if ("$AppName$AppVersion") { "${AppName}_v$AppVersion" } else { "NoId" }
    $ScriptPath = Join-Path -Path $DacPacDir -ChildPath ("DeployScript_{0}_{1}_{2}_{3}.sql" -f $PathDeployId, $ServerName, $Database, $Timestamp)
    $OutputPath = Join-Path -Path $DacPacDir -ChildPath ("DeployScript_{0}_{1}_{2}_{3}.log" -f $PathDeployId, $ServerName, $Database, $Timestamp)

    [System.Collections.ArrayList] $SqlPackageParams = @(
        "/Action:$Action",
        "`"/SourceFile:$Path`"",
        "`"/TargetServerName:$Server`"",
        "`"/TargetDatabaseName:$Database`"",
        "/Variables:DatabaseName=$Database",
        "`"/OutputPath:$ScriptPath`"",
        "/p:IncludeTransactionalScripts=True"
    )
    if ($AppName) {
        $SqlPackageParams.Add("/Variables:AppName=$AppName") | Out-Null
    }
    if ($AppVersion) {
        $SqlPackageParams.Add("/Variables:AppVersion=$AppVersion") | Out-Null
    }
    if ($DeployProfile) {
        $SqlPackageParams.Add("`"/Profile:$DeployProfile`"") | Out-Null
    }
    if ($Property) {
        $Property.GetEnumerator() | ForEach-Object {
            $SqlPackageParams.Add(("/p:{0}={1}" -f $_.Key, $_.Value)) | Out-Null
        }
    }
    if ($Variable) {
        $Variable.GetEnumerator() | ForEach-Object {
            $SqlPackageParams.Add(("/Variable:{0}={1}" -f $_.Key, $_.Value)) | Out-Null
        }
    }
    if ($ArgumentList) {
        $ArgumentList | ForEach-Object {
            $SqlPackageParams.Add($_) | Out-Null
        }
    }

    Write-Verbose "Final parameters: $SqlPackageParams"
    Write-Verbose "Generating SQL Script: $ScriptPath"
    & "$SqlPackageExePath" $SqlPackageParams
    if ($LASTEXITCODE -eq 0) {
        [int] $ColumnsCount = (Get-Host -ErrorAction SilentlyContinue).UI.RawUI.BufferSize.Width - 5
        $ColumnsCount = if (-not $ColumnsCount) { 200 }
        $SqlCmdParams = @(
            "-S", "`"$Server`"",        # The target SQL Server
            "-i", "`"$ScriptPath`"",    # The input script path to run
            "-Y", "$ColumnsCount",      # Max column width
            #"-W"                        # Remove trailing spaces
            "-b",                       # Passes ERRORLEVEL depending on failure or success
            "-o", "`"$OutputPath`""     # Where is the output written to
        )
        Write-Verbose "Final SqlCmd parameters: $SqlCmdParams"
        if ($JoinTransaction.IsPresent) {
            Join-Transactions -Path $ScriptPath
        }
        Write-Verbose "Prepending the run command to the SQL script."
        "-- `"$SqlCmdExePath`" $SqlCmdParams", (Get-Content -Path $ScriptPath) |
            Set-Content -Path $ScriptPath -Encoding utf8

        if (-not $Deploy.IsPresent) {
            Write-Verbose "You can deploy with: SqlCmd.Exe $SqlCmdParams"
        } else {
            Write-Verbose "Deploying SQL script: $ScriptPath"
            if (Test-Path -Path $OutputPath) {
                Remove-Item -Path $OutputPath -ErrorAction Stop
            }

            & "$SqlCmdExePath" $SqlCmdParams
            if ($LASTEXITCODE -ne 0) {
                if (Test-Path -path $OutputPath) {
                    Write-Verbose "Last 10 lines of the ouptut file:"
                    Get-Content -Path $OutputPath -Tail 10
                }
                Write-Error "Deployment of $ScriptPath failed."
            } else {
                Write-Host -ForegroundColor Green "Success."
            }
        }

        Get-Item -Path $ScriptPath
        if (Test-Path -Path $OutputPath) {
            Get-Item -Path $OutputPath
        }
    }
}
