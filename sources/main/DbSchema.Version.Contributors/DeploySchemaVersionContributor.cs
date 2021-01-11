using System.Linq;
using DbSchema.Version.Contributors.Model;
using DbSchema.Version.Contributors.Steps;
using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Extensibility;
using Microsoft.SqlServer.TransactSql.ScriptDom;

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
    public class DeploySchemaVersionContributor : DeploymentPlanModifier
    {
        /// <inheritdoc />
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            PublishMessage(new ExtensibilityError("Applying schema version change into deployment plan.", Severity.Message));

            // If there is no change provided then there is no transaction to bound to.
            // Hence we change the aspect of our model to become non transactional.
            // We're not able to insert the SqlBeginTransactionStep as this is too late to make it.
            var isTransactional = context.Options.IncludeTransactionalScripts &&
                                  context.PlanHandle.Head.NextOfType<SqlBeginTransactionStep>().Any();

            var downgradeInsertionStep = GetDowngradeInsertionStep(context, isTransactional);
            if (downgradeInsertionStep != null)
            {
                var downgradeStep = new DeploySchemaVersionStep(isTransactional,
                    schemaNameSqlCmdVarName: "ApplicationSchemaName",
                    applicationNameSqlCmdVarName: "ApplicationName",
                    applicationVersionSqlCmdVarName: "ApplicationDowngradeVersion");
                AddAfter(context.PlanHandle, downgradeInsertionStep, downgradeStep);
            }

            var upgradeInsertionStep = GetUpgradeInsertionStep(context, isTransactional);
            if (upgradeInsertionStep != null)
            {
                var upgradeStep = new DeploySchemaVersionStep(isTransactional,
                    schemaNameSqlCmdVarName: "ApplicationSchemaName",
                    applicationNameSqlCmdVarName: "ApplicationName",
                    applicationVersionSqlCmdVarName: "ApplicationUpgradeVersion");
                AddBefore(context.PlanHandle, upgradeInsertionStep, upgradeStep);
            }
        }

        private DeploymentStep GetUpgradeInsertionStep(DeploymentPlanContributorContext context, bool isTransactional)
        {
            var desiredStep = context.PlanHandle.Head;
            if (isTransactional)
            {
                var endOfTransaction = desiredStep.NextOfType<SqlEndTransactionStep>().LastOrDefault();
                if (endOfTransaction != null)
                {
                    return endOfTransaction;
                }
            }

            var beginPostDeploymentStep = desiredStep.NextOfType<BeginPostDeploymentScriptStep>().FirstOrDefault();
            if (beginPostDeploymentStep != null)
            {
                return beginPostDeploymentStep;
            }

            return desiredStep;
        }

        private DeploymentStep GetDowngradeInsertionStep(DeploymentPlanContributorContext context, bool isTransactional)
        {
            var desiredStep = context.PlanHandle.Head;
            if (isTransactional)
            {
                var beginTransactionStep = desiredStep.NextOfType<SqlBeginTransactionStep>().LastOrDefault();
                if (beginTransactionStep != null)
                {
                    return beginTransactionStep;
                }
            }

            var endPreDeploymentStep = desiredStep.NextOfType<EndPreDeploymentScriptStep>().FirstOrDefault();
            if (endPreDeploymentStep != null)
            {
                desiredStep = endPreDeploymentStep;
            }

            return desiredStep;
        }
    }
}