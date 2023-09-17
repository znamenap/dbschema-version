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
    $DSPVersion = 150
    $Params = (
        "/p:Configuration=$Configuration",
        "/m:1",
        "/p:DSPVersion=$DSPVersion"
    )
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Contributors.sln" $Params
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Schema.sln" $Params
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Consumer.sln" $Params
    & $ExePath $Command "$PSScriptRoot\..\..\DbSchema.Version.Tools.sln" $Params
}
