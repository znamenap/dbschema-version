# Upgrade and Downgrade Process

## Motivation

Given you've got a task to perform in example a data migration. This data migration would consists of data manipulation between tables or use some computation to get the values. This task could have been performed as part of the PostDeployment script, but then you would get a separate transaction to run and the script could end up eventually in inconsistent state and so the database also. The main aim of the upgrade and downgrade process is to join the data change into the main transaction of the deployment script.

The main goal is achieved by running the particular stored procedures (a.k.a steps) performing the data migration that you authored as part of your development cycle. These stored procedures get deployed together with the schema change into the target database. This ensures the T-SQL integrity and validity of the code performing the migration step. The library then adds the steps to invoke these migration steps in the main transaction.

The next minor goal is to eliminate PostDeployment or PreDeployment script modification between the actual and the next release.

## Who Performs What?

There are responsibilities on both sides: the developer's and the contributor's library sides. This contributor's library is not any silver bullet doing everything, but it helps in certain scenarios only. Thus, it is mainly the developer's responsibility to review the final effect and build the trust based on the experience gained via the usage.

### The Developers Responsibility

The developer's responsibility is mainly to develop the migration steps and to plan and decide the sequence of the migration process to upgrade and downgrade, i.e. in short the step authoring:
- Create two stored procedures within the application's assigned schema per each step for different kind of processes of the both upgrade or downgrade process. Consider the naming of stored procedures to reflect the kind of the process, version of the application and sequence among the other steps.
- Register the step with the ApplicationName, ApplicationSchema, ApplicationVersion, Step Sequence and finally set Upgrade via `[schema_version].[register_upgrade_step] ` or Downgrade via `[schema_version].[register_downgrade_step]`. You perform this registration with [Static Data](STATIC-DATA.MD) feature. This registration must happen before the upgrade process only.
- Diligently test both steps in order to avoid a surprise at deployment time even though still covered via one single transaction.


### The Contributor Library's Responsibility

The contributor's library is responsible for inserting sql statements for running the stored procedures as part of the deployment sequence and only if it matches these conditions:
- The ApplicationSchemaName matches the step's registration record.
- The ApplicationName matches the step's registration record.
- The ApplicationVersion matches the step's registration record.
- The step was not run in the upgrade or downgrade sequence depending to the step's registration record.
- The version the step is bound to was processed yet.

## Why to Support The Downgrade Process

The upgrade and downgrade process is preserved in the main deployment sequence. Nevertheless, it is completely optional. You just do not register any downgrade steps. The downgrade process is supported mainly due to rollback or also known as back-out scenario. These scenarios may happen and they are in certain cases required in some enterprise companies. This downgrade process simply allows reverting back the changes to the previous state and thus generate the script suitable to run to get the database to the previous state in the terms of migration steps. The schema changes would be reflected via the previous version of the dacpac deployment. Thus the sequence of back-out scenarios is:
1. Invoke downgrade process by deploying the actual deployment dacpac with specified ApplicationVersion of the previous value. This performs the downgrade steps in order to revert the actual upgrade migrations steps.
2. Let deploy the previous version of the dacpac to perform the reversible schema changes.

> NOTE: The downgrade as described above is not deployed within one one main transactions but in two per each step and thus you consider using it.
