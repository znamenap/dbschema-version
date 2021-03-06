﻿using System.Collections.Generic;
using System.Linq;
using DbSchema.Version.Contributors.Model;
using DbSchema.Version.Contributors.Steps;
using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Extensibility;

namespace DbSchema.Version.Contributors
{
    /// <summary>
    /// This contributor collects static data specified via *.data.sql and included via DeploymentExtensionConfiguration ItemGroup.
    /// </summary>
    [ExportDeploymentPlanModifier("DbSchema.Version.Contributors.DeployStaticData", "1.0")]
    public class DeployStaticDataContributor : TransactionalDeploymentPlanModifier
    {
        private const string StaticDataModelFileName = "StaticDataModel.data.xml";
        private StaticDataModel model;

        /// <inheritdoc />
        protected override void OnEstablishDeploymentConfiguration(DeploymentContributorConfigurationSetup setup)
        {
            var inputs = setup.EnumerateInputs()
                .Where(s => StaticDataModel.IsStaticDataDeploymentUnit(s.Filename))
                .ToArray();
            if (inputs.Length > 0)
            {
                model = StaticDataModel.Create();
                foreach (var input in inputs)
                {
                    using (var inputStream = input.GetStream())
                    {
                        PublishMessage(new ExtensibilityError(
                            $"Including {input.Filename} into static data deployment model.", Severity.Message));
                        model.Add(input.Filename, inputStream);
                    }
                }

                var metadata = new Dictionary<string, string>();
                using (var stream = setup.OpenNewOutput(StaticDataModelFileName, metadata))
                {
                    model.Save(stream);
                    stream.Flush();
                }
            }
        }

        /// <inheritdoc />
        protected override void OnApplyDeploymentConfiguration(DeploymentContributorContext context,
            ICollection<DeploymentContributorConfigurationStream> configurationStreams)
        {
            var configurationStream = configurationStreams.FirstOrDefault(s => s.Filename == StaticDataModelFileName);
            if (configurationStream != null)
            {
                PublishMessage(new ExtensibilityError(
                    "Reading static data model into deployment plan.", Severity.Message));
                using (var modelStream = configurationStream.GetStream())
                {
                    model = StaticDataModel.Load(modelStream);
                }
            }
        }

        /// <inheritdoc />
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            if (model == null)
            {
                PublishMessage(new ExtensibilityError($"There isn't a static data model available in this deployment.", Severity.Warning));
                return;
            }

            PublishMessage(new ExtensibilityError("Applying static data model items into deployment plan.", Severity.Message));

            var isTransactional = context.Options.IncludeTransactionalScripts;
            EnsureItHasTransactionStep(context, isTransactional);

            var deploymentStep = new DeployStaticDataModelStep(model, isTransactional);
            var insertionStep = GetSqlEndTransactionStep(context, isTransactional);
            AddBefore(context.PlanHandle, insertionStep, deploymentStep);
        }
    }
}
