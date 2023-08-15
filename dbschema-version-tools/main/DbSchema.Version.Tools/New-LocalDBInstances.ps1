<#
.SYNOPSIS
    Creates new Local SQL DB instances.
.DESCRIPTION
    Creates new Local SQL DB instances with the name of InstanceMask being masked with DSPVersion. It can also
    recreate the existing isntance via Force parameter and optionally use the SQLLocalDB.exe specified via SQLLocalDBExePath
    parameter.

    Prerequisities:
    You would at best have installed versions of these:
    120 : SQL Server 2014 : https://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/LocalDB%2064BIT/SqlLocalDB.msi
    130 : SQL Server 2016 : https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SqlLocalDB.msi
    140 : SQL Server 2017 : https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SqlLocalDB.msi
    150 : SQL Server 2019 : https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SqlLocalDB.msi

    Silent installation (run as admin):
        PS> msiexec /qb /i SqlLocalDB.msi IACCEPTSQLLOCALDBLICENSETERMS=YES

.PARAMETER SQLLocalDBExePath
    Path to the SQLLocalDB.exe if not available at standard places.
.PARAMETER DSPVersion
    The versions of SQL Local DB to create the local db instances for.
.PARAMETER Force
    Force the recreation of the instance.
.PARAMETER InstanceMask
    The mask of the instance with {0} placeholder to be replaced with DSPVersion item.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $SQLLocalDBExePath,

    [Parameter()]
    [string[]] $DSPVersion = ('120', '130', '140', '150'),

    [Parameter()]
    [switch] $Force,

    [Parameter()]
    [string] $InstanceMask = 'LocalDB_{0}_BUILD'
)
begin {
    $ErrorActionPreference = 'Stop'

    function Get-LatestVersionExePath {
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
            } else {
                $Location | ForEach-Object { Write-Debug "Observing: $_\$ExeName"; Write-Output "$_\$ExeName" } |
                    Where-Object { Test-Path -Path $_ } |
                    Get-Item -ErrorAction SilentlyContinue |
                    Sort-Object -Property VersionInfo -Descending |
                    ForEach-Object {
                        Write-Debug ("Observed: {0}({1}): {2}" -f $_.Name, $_.VersionInfo.FileVersion, $_.FullName); $_
                    } |
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

    $SQLLocalDBExePath = Get-LatestVersionExePath -ExeName "SQLLocalDB.exe" -Path $SQLLocalDBExePath -Location @(
        "$PSScriptRoot",
        "$PSScriptRoot\bin",
        "${env:ProgramFiles}\Microsoft SQL Server\*\Tools\Binn",
        "${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn",
        "${env:ProgramFiles(x86)}\Microsoft SQL Server\*\Tools\Binn",
        "${env:ProgramFiles(x86)}\Microsoft SQL Server\Client SDK\ODBC\*\Tools\Binn",
        $env:Path.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
    )
}
process {
    $ExistingInstances = & "$SQLLocalDBExePath" info | ForEach-Object { $_.Trim() } | Where-Object { $_ } | ForEach-Object {
        Write-Verbose "Identified existing instance: $_"
        Write-Output $_
    }
    foreach($DSPVersionItem in $DSPVersion) {
        $DiscoveryExeFile = "${env:ProgramFiles}\Microsoft SQL Server\$DSPVersionItem\Tools\Binn\sqllocaldb.exe"
        $VersionInfo = Get-Item $DiscoveryExeFile | ForEach-Object VersionInfo
        $InstanceName = ($InstanceMask -f $DSPVersionItem)
        $Exists = $ExistingInstances | Where-Object { $_ -ieq $InstanceName }
        $InstanceName = ('"{0}"' -f $InstanceName)

        Write-Debug "Exists: $Exists"
        Write-Debug "Force: $Force"
        if ($Exists -and ($Force.IsPresent)) {
            Write-Verbose "Stopping and deleting the existing instance $InstanceName"
            & "$SQLLocalDBExePath" stop $InstanceName -i
            & "$SQLLocalDBExePath" delete $InstanceName
        }

        if ($Exists -and -not ($Force.IsPresent)) {
            Write-Warning "SQLLocalDB instance $InstanceName already exists. Use -Force switch to renew it also."
        } else {
            Write-Verbose "Creatig a new instance $InstanceName"
            & "$SQLLocalDBExePath" create $InstanceName ($VersionInfo.ProductVersion)
        }
    }
}
