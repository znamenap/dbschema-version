[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $ContributorsPath,

    [Parameter()]
    [string] $BuildTargets = "Publish",

    [Parameter()]
    [string] $SqlPublishProfilePath = "$PSScriptRoot\Application.Schema.Template\Application.Schema.Template.publish.xml",

    [Parameter()]
    [string] $SqlProjPath = "$PSScriptRoot\Application.Schema.Template\Application.Schema.Template.sqlproj",

    [Parameter()]
    [string] $ContributorsFilter = 'DbSchema.Version.Contributors.*',

    [Parameter()]
    [string] $TargetPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\Extensions\Microsoft\SQLDB\Dac\150\Extensions\",

    [Parameter()]
    [string[]] $MSBuildParams = @(),

    [Parameter()]
    [string] $Configuration = 'Debug'
)
begin {
    $VSCMD = Get-Command -Name "Use-VisualStudioEnvironment"
    if ($VSCMD) {
        Use-VisualStudioEnvironment
    }
}
process {
    $ContributorsPath = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($ContributorsPath)
    $SqlProjPath = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($SqlProjPath)
    $TargetPath = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($TargetPath)
    $TargetPath = New-Item -ItemType Directory -Path $TargetPath -Force | ForEach-Object FullName
    $TargetFiles = @()
    try {
        Get-ChildItem -Path $ContributorsPath -Filter $ContributorsFilter |
            Copy-Item -Recurse -Force -ErrorAction Stop -Destination $TargetPath -PassThru |
                ForEach-Object { $TargetFiles += $_.FullName; $_ } |
                    Format-Table -GroupBy Directory

        Set-ItemProperty -Path $SqlProjPath -Name LastWriteTime -Value ([datetime]::Now)

        & msbuild.exe -NoLogo $SqlProjPath /p:Configuration=$Configuration "/t:$BuildTargets" "/p:SqlPublishProfilePath=$SqlPublishProfilePath" $MSBuildParams
    } finally {
        Remove-Item -Verbose -Force -Path $TargetFiles
    }
}
