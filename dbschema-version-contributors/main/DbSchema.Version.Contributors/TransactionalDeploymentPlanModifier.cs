using System.Linq;
using DbSchema.Version.Contributors.Model;
using DbSchema.Version.Contributors.Steps;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors
{
    /// <summary>
    /// Abstract DeploymentPlanModifier that ensures to add transactional script statements
    /// if the flag of transactional script was set to true.
    /// </summary>
    public abstract class TransactionalDeploymentPlanModifier : DeploymentPlanModifier
    {
        /// <summary>
        /// If there is no change provided then there is no transaction to bound to.
        /// Hence we change the aspect of our model to become non transactional.
        /// We're not able to insert the SqlBeginTransactionStep as this is too late to make it.
        /// </summary>
        /// <param name="context">The context of the deployment.</param>
        /// <param name="isTransactional">Indicator if required transaction, it is usually context.Options.IncludeTransactionalScripts value to be provided.</param>
        protected void EnsureItHasTransactionStep(DeploymentPlanContributorContext context, bool isTransactional)
        {
            if (isTransactional && IsMissingTransactionStep(context))
            {
                AddTransactionStep(context);
            }
        }

        private static bool IsMissingTransactionStep(DeploymentPlanContributorContext context)
        {
            return !context.PlanHandle.Head.NextOfType<SqlBeginTransactionStep>().Any() &&
                   !context.PlanHandle.Head.NextOfType<CustomSqlBeginTransactionStep>().Any();
        }

        /// <summary>
        /// Adds the Begin and End transactional aspects into the deployment plan.
        /// </summary>
        /// <param name="context">The deployment plan context.</param>
        protected void AddTransactionStep(DeploymentPlanContributorContext context)
        {
            var head = context.PlanHandle.Head;
            if (!head.NextOfType<CustomSqlBeginTransactionStep>().Any())
            {
                var endPreDeploymentStep = head.NextOfType<EndPreDeploymentScriptStep>().FirstOrDefault();
                if (endPreDeploymentStep != null)
                {
                    var customSqlBeginTransactionStep = new CustomSqlBeginTransactionStep();
                    AddAfter(context.PlanHandle, endPreDeploymentStep, customSqlBeginTransactionStep);
                }
            }

            if (!head.NextOfType<CustomSqlEndTransactionStep>().Any())
            {
                var beginPostDeploymentStep = head.NextOfType<BeginPostDeploymentScriptStep>().FirstOrDefault();
                if (beginPostDeploymentStep != null)
                {
                    var customSqlEndTransactionStep = new CustomSqlEndTransactionStep();
                    AddBefore(context.PlanHandle, beginPostDeploymentStep, customSqlEndTransactionStep);
                }
            }
        }

        /// <summary>
        /// Returns the SqlEndDeploymentStep where you can AddBefore the next steps as part of the transaction.
        /// </summary>
        /// <param name="context">The deployment plan context.</param>
        /// <param name="isTransactional">Indicator if required transaction, it is usually context.Options.IncludeTransactionalScripts value to be provided.</param>
        /// <returns>The deployment step where the transaction ends.</returns>
        protected DeploymentStep GetSqlEndTransactionStep(DeploymentPlanContributorContext context, bool isTransactional)
        {
            var desiredStep = context.PlanHandle.Head;
            if (isTransactional)
            {
                var endOfTransaction = desiredStep.NextOfType<SqlEndTransactionStep>().LastOrDefault();
                if (endOfTransaction != null)
                {
                    return endOfTransaction;
                }

                var customEndOfTransaction = desiredStep.NextOfType<CustomSqlEndTransactionStep>().LastOrDefault();
                if (customEndOfTransaction != null)
                {
                    return customEndOfTransaction;
                }
            }

            var beginPostDeploymentStep = desiredStep.NextOfType<BeginPostDeploymentScriptStep>().FirstOrDefault();
            if (beginPostDeploymentStep != null)
            {
                return beginPostDeploymentStep;
            }

            return desiredStep;
        }

        /// <summary>
        /// Returns the SqlBeginDeploymentStep where you can AddAfter the next steps as part of the transaction.
        /// </summary>
        /// <param name="context">The deployment plan context.</param>
        /// <param name="isTransactional">Indicator if required transaction, it is usually context.Options.IncludeTransactionalScripts value to be provided.</param>
        /// <returns>The deployment step where the transaction begins.</returns>
        protected DeploymentStep GetSqlBeginTransactionStep(DeploymentPlanContributorContext context, bool isTransactional)
        {
            var desiredStep = context.PlanHandle.Head;
            if (isTransactional)
            {
                var beginTransactionStep = desiredStep.NextOfType<SqlBeginTransactionStep>().LastOrDefault();
                if (beginTransactionStep != null)
                {
                    return beginTransactionStep;
                }

                var customEndOfTransaction = desiredStep.NextOfType<CustomSqlBeginTransactionStep>().LastOrDefault();
                if (customEndOfTransaction != null)
                {
                    return customEndOfTransaction;
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