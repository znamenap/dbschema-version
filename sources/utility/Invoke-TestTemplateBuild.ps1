<#
.SYNOPSIS
    The script invokes developer's local testing scenario to publish the changes into SQL script according to the publish profile.
.DESCRIPTION
    Creates the target folder of extension contributes at $TargetPath and copies the contributor files over there. Then
    it starts MSBuild to invoke the $BuildTargets (i.e. Publish by default) the $SqlProjPath according the $SqlPublishProfilePath. WHen it completed the deployment or there was an error, it removes the contributor files.
.EXAMPLE
    PS> .\Invoke-TestTemplateBuild.ps1 -ContributorsPath .\output\main\bin\Debug\net4.6.2
    Invokes the steps to publish the SQLPROJ while using the contributors.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $ContributorsPath,

    [Parameter()]
    [string] $BuildTargets = "Publish",

    [Parameter()]
    [string] $SqlPublishProfilePath = "$PSScriptRoot\..\schema\Application.Schema.Template\Application.Schema.Template.publish.xml",

    [Parameter()]
    [string] $SqlProjPath = "$PSScriptRoot\..\schema\Application.Schema.Template\Application.Schema.Template.sqlproj",

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

        & msbuild.exe -NoLogo $SqlProjPath /p:Configuration=$Configuration /p:Platform=AnyCPU "/t:Build;$BuildTargets" "/p:SqlPublishProfilePath=$SqlPublishProfilePath" $MSBuildParams
    } finally {
        Remove-Item -Verbose -Force -Path $TargetFiles
    }
}
