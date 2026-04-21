[CmdletBinding()]
param(
    [Parameter()]
    [string] $Configuration = "Debug",

    [Parameter()]
    [string] $ExePath = "dotnet.exe",

    [Parameter()]
    [string] $Command = "build"
)
process {
    Remove-Item -Recurse -Force $PSScriptRoot\..\..\output
    $DSPVersion = 160
    $Params = (
        "/p:Configuration=$Configuration",
        "/m:1",
        "/p:DSPVersion=$DSPVersion"
    )
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Contributors.slnx" $Params
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Schema.slnx" $Params
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Consumer.slnx" $Params
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Tools.slnx" $Params
}
