using DbSchema.Version.Contributors.Steps;

using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Extensibility;

namespace DbSchema.Version.Contributors
{
    /// <summary>
    /// This contributor invokes [schema_version].[invoke_version_change] as part of the transaction.
    /// </summary>
    /// <remarks>
    /// If the source version is lower than target version then it performs downgrade at the beginning of the transactional parts.
    /// If the source version is greater than or equal to the target version then it performs the upgrade at the end of the transactional parts.
    /// </remarks>
    [ExportDeploymentPlanModifier("DbSchema.Version.Contributors.DeploySchemaVersion", "1.0")]
    public class DeploySchemaVersionContributor : TransactionalDeploymentPlanModifier
    {
        public DeploySchemaVersionContributor()
        {

        }
        /// <inheritdoc />
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            PublishMessage(new ExtensibilityError("Applying schema version change into deployment plan.", Severity.Message));

            var isTransactional = context.Options.IncludeTransactionalScripts;
            EnsureItHasTransactionStep(context, isTransactional);

            var downgradeInsertionStep = GetSqlBeginTransactionStep(context, isTransactional);
            if (downgradeInsertionStep != null)
            {
                var downgradeStep = new DeploySchemaVersionStep(isTransactional,
                    schemaNameSqlCmdVarName: "ApplicationSchemaName",
                    applicationNameSqlCmdVarName: "ApplicationName",
                    applicationVersionSqlCmdVarName: "ApplicationDowngradeVersion");
                AddAfter(context.PlanHandle, downgradeInsertionStep, downgradeStep);
            }

            var upgradeInsertionStep = GetSqlEndTransactionStep(context, isTransactional);
            if (upgradeInsertionStep != null)
            {
                var upgradeStep = new DeploySchemaVersionStep(isTransactional,
                    schemaNameSqlCmdVarName: "ApplicationSchemaName",
                    applicationNameSqlCmdVarName: "ApplicationName",
                    applicationVersionSqlCmdVarName: "ApplicationUpgradeVersion");
                AddBefore(context.PlanHandle, upgradeInsertionStep, upgradeStep);
            }
        }
    }
}