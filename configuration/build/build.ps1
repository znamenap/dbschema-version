[CmdletBinding()]
param(
    [Parameter()]
    [string] $Configuration = "Debug",

    [Parameter()]
    [string] $MSBuildExePath = "C:\Program Files\Microsoft\VisualStudio\2022\Professional\MSBuild\Current\Bin\amd64\MSBuild.exe"
)
process {
    Remove-Item -Recurse -Force $PSScriptRoot\..\..\output
    & $MSBuildExePath $PSScriptRoot\..\..\DbSchema.Version.Main.sln "/t:restore;rebuild" /p:Configuration=$Configuration /m:1 
    & $MSBuildExePath $PSScriptRoot\..\..\DbSchema.Version.Schema.sln "/t:restore;rebuild"  /p:Configuration=$Configuration /m:1
}
