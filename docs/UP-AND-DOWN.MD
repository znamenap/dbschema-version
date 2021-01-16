# Upgrade and Downgrade Process

## Motivation

Given you've got a task to perform in example a data migration. This data migration would consists of data manipulation between tables or use some computation to get the values. This task could have been performed as part of the PostDeployment script, but then you would get a separate transaction to run and the script could end up eventually in inconsistent state and so the database also. The main aim of the upgrades and downgrades is to join the data change management into the main transaction of the deployment script.

The main goal is achieved by running the particular migration stored procedures (a.k.a steps) that you authored as part of your development cycle. These stored procedure gets deployed together with the schema into the database. This ensures the T-SQL integrity and validity of the code performing the migration.

The next goal is to eliminate PostDeployment or PreDeployment script modification between each release.

## Who Performs What?

There are responsibilities on both sides: the developer's and the contributor's library.

### The Developers Responsibility

The developer's responsibility is mainly to develop the migration steps and plan and decide the sequence of the process to upgrade and downgrade, i.e. in short the step authoring:
- Create two stored procedures within the application's assigned schema. Each for different kind of process of the both upgrade or downgrade. Consider the naming of stored procedures to reflect the kind or process, version of the application and sequence in the steps.
- Register the step with the ApplicationName, ApplicationSchema, ApplicationVersion, Step Sequence, Upgrade via `[schema_version].[register_upgrade_step] ` or Downgrade via `[schema_version].[register_downgrade_step]`. You perform this registration with [Static Data](STATIC-DATA.MD) feature. This happens before the upgrade process.
- Diligently test both steps in order to avoid the surprise at deployment time even though still covered via one single transaction.


### The Contributor Library's Responsibility

The contributor's library is responsible for running the stored procedures as part of the deployment sequence and only if it matches these conditions:
- The ApplicationSchemaName matches the step registration record.
- The ApplicationName matches the step registration record.
- The ApplicationVersion matches the step registration record.
- The step was not run in the upgrade or downgrade sequence depending to the step's registration record.
- The version the step is bound to was processed yet.

