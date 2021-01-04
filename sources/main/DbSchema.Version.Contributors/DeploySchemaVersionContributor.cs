using System.Collections.Generic;
using System.Linq;
using System.Text;
using DbSchema.Version.Contributors.Model;
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
    public class DeploySchemaVersionContributor : DeploymentPlanModifier
    {
        /// <inheritdoc />
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            PublishMessage(new ExtensibilityError("Applying schema version change into deployment plan.", Severity.Message));

            var downgradeInsertionStep = GetDowngradeInsertionStep(context);
            if (downgradeInsertionStep != null)
            {
                var downgradeStep = new DeploySchemaVersionStep(context.Options.IncludeTransactionalScripts,
                    schemaNameSqlCmdVarName: "ApplicationSchemaName",
                    applicationNameSqlCmdVarName: "ApplicationName",
                    applicationVersionSqlCmdVarName: "ApplicationDowngradeVersion");
                AddAfter(context.PlanHandle, downgradeInsertionStep, downgradeStep);
            }

            var upgradeInsertionStep = GetUpgradeInsertionStep(context);
            if (upgradeInsertionStep != null)
            {
                var upgradeStep = new DeploySchemaVersionStep(context.Options.IncludeTransactionalScripts,
                    schemaNameSqlCmdVarName: "ApplicationSchemaName",
                    applicationNameSqlCmdVarName: "ApplicationName",
                    applicationVersionSqlCmdVarName: "ApplicationUpgradeVersion");
                AddBefore(context.PlanHandle, upgradeInsertionStep, upgradeStep);
            }
        }

        private DeploymentStep GetUpgradeInsertionStep(DeploymentPlanContributorContext context)
        {
            DeploymentStep desiredStep = context.PlanHandle.Head;
            if (context.Options.IncludeTransactionalScripts)
            {
                var endOfTransaction = desiredStep.NextOfType<SqlEndTransactionStep>().LastOrDefault();
                if (endOfTransaction == null)
                {
                    PublishMessage(new ExtensibilityError(
                        "Deployment profile has enabled IncludeTransactionalScripts but missing SqlEndTransactionStep.",
                        Severity.Error));
                    return desiredStep;
                }

                desiredStep = endOfTransaction;
            }
            else
            {
                var beginPostDeploymentStep = desiredStep.NextOfType<BeginPostDeploymentScriptStep>().FirstOrDefault();

                if (beginPostDeploymentStep == null)
                {
                    desiredStep = context.PlanHandle.Tail;
                }
                else
                {
                    desiredStep = beginPostDeploymentStep;
                }
            }

            return desiredStep;
        }

        private DeploymentStep GetDowngradeInsertionStep(DeploymentPlanContributorContext context)
        {
            DeploymentStep desiredStep = context.PlanHandle.Head;
            if (context.Options.IncludeTransactionalScripts)
            {
                var beginTransactionStep = desiredStep.NextOfType<SqlBeginTransactionStep>().LastOrDefault();
                if (beginTransactionStep == null)
                {
                    PublishMessage(new ExtensibilityError(
                        "Deployment profile has enabled IncludeTransactionalScripts but missing SqlBeginTransactionStep.",
                        Severity.Error));
                    return desiredStep;
                }

                desiredStep = beginTransactionStep.Next;
            }
            else
            {
                var endPreDeploymentStep = desiredStep.NextOfType<EndPreDeploymentScriptStep>().FirstOrDefault();

                if (endPreDeploymentStep == null)
                {
                    desiredStep = context.PlanHandle.Head;
                }
                else
                {
                    desiredStep = endPreDeploymentStep.Next;
                }
            }

            return desiredStep;
        }
    }
}