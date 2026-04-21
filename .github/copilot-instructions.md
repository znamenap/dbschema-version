# Copilot Instructions for dbschema-version

## Project Overview

This repository contains **DbSchema.Version**, a hybrid MSSQL database deployment library built on SSDT (SQL Server Data Tools). It combines state-based and change-based SQL deployment models. The solution provides:

- **SSDT Deployment Contributors** (C# library): MSBuild extensions that modify the DacPac deployment plan at build/deploy time.
- **SQL Schema DacPac** (`schema_version` schema): The SQL schema deployed into target databases to track application versions and migration steps.
- **Consumer template**: An example SQL project that consumes the library.
- **Tools**: PowerShell utility scripts for local development.

## Repository Structure

```
/
├── Directory.Build.props          # Root MSBuild properties (version, company, .NET options)
├── Directory.Build.targets        # Root MSBuild targets (git versioning, clean, build)
├── global.json                    # .NET SDK pin (6.0.x) and MSBuild SDK versions
├── .config/dotnet-tools.json      # dotnet tool manifest (sqlpackage, dotnetsay)
│
├── DbSchema.Version.Contributors.sln   # Solution: C# contributors + unit tests
├── DbSchema.Version.Schema.sln         # Solution: SQL DacPac schema (requires Windows/SSDT)
├── DbSchema.Version.Consumer.sln       # Solution: Consumer SQL project template
├── DbSchema.Version.Tools.sln          # Solution: PowerShell utility tools
│
├── dbschema-version-contributors/
│   ├── main/DbSchema.Version.Contributors/   # C# library (netstandard2.0)
│   │   ├── DeploySchemaVersionContributor.cs  # Injects version-change SQL into deployment plan
│   │   ├── DeployStaticDataContributor.cs     # Injects *.data.sql files into deployment plan
│   │   ├── ModelStatisticsContributor.cs      # Generates model statistics XML
│   │   ├── RestartableScriptContributor.cs    # Makes deployment scripts re-runnable
│   │   ├── UpdateReportContributor.cs         # Generates deployment plan report
│   │   ├── TransactionalDeploymentPlanModifier.cs  # Base class for transactional modifiers
│   │   ├── DBSchema.Version.Contributors.targets   # MSBuild targets imported by SQL projects
│   │   ├── Steps/                             # DeploymentStep implementations
│   │   └── Model/                             # Model helpers
│   └── test/DbSchema.Version.Contributors.UnitTests/   # Unit tests (net6.0)
│
├── dbschema-version-schema/
│   └── main/DbSchema.Version/    # SQL project (Microsoft.Build.Sql SDK)
│       └── Feature/              # SQL objects: Version, Step, Audit, Shared
│
├── dbschema-version-consumer/
│   └── main/Application.Schema.Template/  # Consumer SQL project template
│
├── dbschema-version-tools/
│   └── main/DbSchema.Version.Tools/       # PowerShell scripts
│
└── configuration/
    ├── build/                    # build.ps1, deploy.ps1, NuGet readme
    ├── docs/                     # Markdown documentation
    └── globals/                  # Shared MSBuild globals
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Contributors library | C# / netstandard2.0 |
| Unit tests | C# / net6.0 |
| SQL schema | Microsoft.Build.Sql SDK (DacPac) |
| Build system | MSBuild / dotnet CLI |
| .NET SDK | 6.0.x (see `global.json`) |
| Key NuGet deps | `Microsoft.SqlServer.DacFx 150.4897.1`, `Microsoft.Build.Framework 15.9.20`, `System.ComponentModel.Composition 5.0.0` |
| SQL tools | `sqlpackage` (dotnet tool, v162.0.52) |

## Building

### What can be built on Linux (CI / Copilot environment)

The **C# contributors library and unit tests** build on Linux with standard .NET 6:

```bash
# Restore and build the contributors library
dotnet build DbSchema.Version.Contributors.sln

# Run unit tests
dotnet test DbSchema.Version.Contributors.sln
```

### What requires Windows

The **SQL DacPac schema** and **consumer** solutions use `Microsoft.Build.Sql` and require:
- Windows or `sqlpackage` + SQL Server for deployment/publish operations
- `(localdb)\ProjectsV13` or a named LocalDB instance for local development

The schema project (`DbSchema.Version.Schema.sln`) **can be built** on Linux using the `Microsoft.Build.Sql` SDK, but **deployment/publish targets** require a SQL Server connection.

### Full build (Windows, PowerShell)

```powershell
.\configuration\build\build.ps1 -Configuration Release
```

This script calls `dotnet build` across all four solutions in order.

### Version calculation

Versions are computed in `Directory.Build.targets` from `MajorVersion`, `MinorVersion`, `PatchVersion` in `Directory.Build.props`, combined with git branch/commit info. The current version is **2.0.x**.

## MSBuild Properties for Contributors

Consumer SQL projects configure contributors via MSBuild properties **before** importing `DBSchema.Version.Contributors.targets`:

| Property | Default | Effect |
|----------|---------|--------|
| `DeployStaticDataEnabled` | `false` | Deploys `*.data.sql` files within the main transaction |
| `DeploySchemaVersionEnabled` | `false` | Injects `[schema_version].[invoke_version_change]` upgrade/downgrade calls |
| `RestartableScriptEnabled` | `false` | Wraps batches so the script can be re-run after errors (incompatible with `DeploySchemaVersionEnabled`) |
| `UpdateReportEnabled` | `false` | Generates an XML deployment plan report |
| `ModelStatisticsEnabled` | `false` | Generates an XML model statistics file |

## Key Design Concepts

- **Contributors** are MEF-exported (`[ExportDeploymentPlanModifier]` / `[ExportBuildContributor]`) classes loaded by DacFx at build/deploy time.
- **TransactionalDeploymentPlanModifier** is the base class for contributors that need to insert steps around the SQL transaction boundaries (`BEGIN TRANSACTION` / `COMMIT TRANSACTION`).
- The `DBSchema.Version.Contributors.targets` file wires contributors into the SQL project's build/deploy pipeline and is the MSBuild integration point.
- The `schema_version` SQL schema (in the DacPac) must be referenced by consumer SQL projects as an "Application Tier" database reference to the same database.
- SqlCmd variables `ApplicationSchemaName`, `ApplicationName`, `ApplicationUpgradeVersion`, and `ApplicationDowngradeVersion` are used at deployment time to control versioning behaviour.

## Code Style

- C# follows editorconfig rules in `.editorconfig`: 4-space indentation, CRLF line endings, Allman braces, `var` preferred, PascalCase for types and methods.
- Nullable is **disabled** (`<Nullable>disable</Nullable>`).
- Implicit usings are **disabled** (`<ImplicitUsings>disable</ImplicitUsings>`).
- Warning level 4.

## Documentation

Additional documentation lives in `configuration/docs/`:
- `REFERENCING.MD` – how to reference the NuGet package in a SQL project
- `STATIC-DATA.MD` – how to use the static data contributor
- `VERSIONING.MD` – how version tracking works
- `UP-AND-DOWN.MD` – upgrade/downgrade process
- `DEPLOYMENT.MD` – deployment process
