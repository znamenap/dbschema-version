# Referencing

## NuGet Package Structure

```cmd
DbSchema.Version.nupkg
|
+-- content\
|   | 
|   +-- Example.Schema\
|       | 
|       +-- < SqlProject showing the use cases >
|
+-- build\
|   | 
|   +-- DbSchema.Version.Contributors.targets
|   +-- DbSchema.Version.Contributors.dll
|   +-- DbSchema.Version.Contributors.pdb
|   +-- DbSchema.Version.Contributors.xml
|   +-- DbSchema.Version.Tasks.dll
|   +-- DbSchema.Version.Tasks.pdb
|
+-- schema\
|   | 
|   +-- \120\
|       | 
|       +-- DbSchema.Version.dacpac
|
+-- tools\
|   | 
|   +-- New-DatabaseAttachScript.ps1
|   +-- Export-SqlDeadlock.ps1
|
+-- DbSchema.Version.nuspec
+-- Readme-DbSchema.Version.txt
```

## Referencing DacPac

As of nbow any .sqlproj project does not support referencing NuGet packages. Nevertheless, you can workaround it by referencing this NuGet package into your other .NET project supporting NuGet package referencing; perhaps the main application or library. Then you can add the reference to DbSchema.Version.dacpac from your .sqlproj file. This dependency ensure coping the DbVersion.Schema.dacpac side by side to the output path of yours .sqlproj project.

## Referencing Contributors

The DBSchema.Version.Contributors and DbSchema.Version.Tasks assemblies are essential part and required to project DbSchema.Version to its full fledged features in the SqlDeploy and SqlPublish build phases and hence in order to make the dependency as simple as possible, you have to manually modify your .sqlproj once only. You must modify so that you introduce an import statement of the file \<your-packages-location>\DbSchema.Version.X.Y.Z\DbSchema.Version.Contributors.targets that is distributed with the NuGet package. You must put the import statement just after the import statement for the last SSDT targets. In example, it should look like the last line of this fragment:
```xml
  <Import Condition="'$(SQLDBExtensionsRefPath)' != ''" Project="$(SQLDBExtensionsRefPath)\Microsoft.Data.Tools.Schema.SqlTasks.targets" />
  <Import Condition="'$(SQLDBExtensionsRefPath)' == ''" Project="$(MSBuildExtensionsPath)\Microsoft\VisualStudio\v$(VisualStudioVersion)\SSDT\Microsoft.Data.Tools.Schema.SqlTasks.targets" />
  <Import Project="..\packages\DbSchema.Version.x.y.z\build\DbSchema.Version.Contributors.targets" />
```

