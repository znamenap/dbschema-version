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
        $env:Path -split ';'
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
