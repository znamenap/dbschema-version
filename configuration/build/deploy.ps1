[CmdletBinding()]
param(
    [Parameter()]
    [string] $Configuration = "Debug",

    [Parameter()]
    [string] $ExePath = "dotnet.exe",
    
    [Parameter()]
    [string[]] $Parameter

)
process {
    $DSPVersion = 150
    $Params = (
        "/Action:Publish",
        "/TargetServerName:(localdb)\MSSQLLocalDB",
        "/TargetDatabaseName:DBSchemaVersion",
        "/SourceFile:.\output\schema\main\$DSPVersion\bin\$Configuration\DbSchema.Version.dacpac", 
        "/ReferencePaths:.\output\schema\main\$DSPVersion\bin\$Configuration\",
        "/v:Configuration=$Configuration",
        "/v:DSPVersion=$DSPVersion",
        "/p:IncludeCompositeObjects=true",
        "/p:BlockOnPossibleDataLoss=true",
        "/p:IncludeTransactionalScripts=true"
    )
    $Params += $Parameter
    & $ExePath sqlpackage $Params
}
