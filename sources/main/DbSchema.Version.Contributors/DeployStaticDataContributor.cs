using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using DbSchema.Version.Contributors.Model;
using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Extensibility;

namespace DbSchema.Version.Contributors
{
    /// <summary>
    /// This contributor collects static data specified via *.data.sql and included via DeploymentExtensionConfiguration ItemGroup.
    /// </summary>
    [ExportDeploymentPlanModifier("DbSchema.Version.Contributors.DeployStaticData", "1.0")]
    public class DeployStaticDataContributor : DeploymentPlanModifier
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
                PublishMessage(new ExtensibilityError($"There isn't a static data model available in this deployment.",
                    Severity.Warning));
                return;
            }

            PublishMessage(new ExtensibilityError("Applying static data model items into deployment plan.",
                Severity.Message));
            DeploymentStep insertionStep;
            if (context.Options.IncludeTransactionalScripts)
            {
                var endOfTransaction = context.PlanHandle.Head.NextOfType<SqlEndTransactionStep>().LastOrDefault();
                if (endOfTransaction == null)
                {
                    PublishMessage(new ExtensibilityError(
                        "Deployment profile has enabled IncludeTransactionalScripts but missing SqlEndTransactionStep.",
                        Severity.Error));
                    return;
                }

                insertionStep = endOfTransaction.Previous;
            }
            else
            {
                var beginPostDeploymentStep =
                    context.PlanHandle.Head.NextOfType<BeginPostDeploymentScriptStep>().FirstOrDefault();

                if (beginPostDeploymentStep == null)
                {
                    insertionStep = context.PlanHandle.Tail;
                }
                else
                {
                    insertionStep = beginPostDeploymentStep.Previous;
                }
            }

            var batch = new StringBuilder();
            foreach (var staticDataModelItem in model.GetItems())
            {
                batch.Length = 0;
                batch.AppendLine();
                batch.AppendLine();
                batch.AppendLine($"-- Input File Name: {staticDataModelItem.Item1}");
                batch.AppendLine(staticDataModelItem.Item2.TrimEnd());
                if (context.Options.IncludeTransactionalScripts)
                {
                    batch.AppendLine("go");
                    batch.AppendLine("if @@error <> 0 and @@trancount > 0 begin rollback; end");
                    batch.AppendLine(
                        "if @@trancount = 0 begin insert into #tmperrors(error) values (1); begin transaction; end");
                }

                var sqlBatch = new DeploymentScriptStep(batch.ToString());
                AddAfter(context.PlanHandle, insertionStep, sqlBatch);
                insertionStep = sqlBatch;
            }
        }
    }

    /// <inheritdoc />
    public class DeployStaticDataModelStep : DeploymentStep
    {
        private readonly StaticDataModel model;
        private readonly bool isTransactional;

        /// <inheritdoc />
        public DeployStaticDataModelStep(StaticDataModel model, bool isTransactional)
        {
            this.model = model;
            this.isTransactional = isTransactional;
        }

        /// <inheritdoc />
        public override IList<string> GenerateTSQL()
        {
            var batch = new List<string>();
            foreach (var staticDataModelItem in model.GetItems())
            {
                batch.Add(Environment.NewLine);
                batch.Add(Environment.NewLine);
                batch.Add($"-- Input File Name: {staticDataModelItem.Item1}{Environment.NewLine}");
                batch.Add(staticDataModelItem.Item2.TrimEnd()+Environment.NewLine);
                if (isTransactional)
                {
                    batch.Add($"go{Environment.NewLine}");
                    batch.Add($"if @@error <> 0 and @@trancount > 0 begin rollback; end{Environment.NewLine}");
                    batch.Add($"if @@trancount = 0 begin insert into #tmperrors(error) values (1); begin transaction; end{Environment.NewLine}");
                }
            }

            return batch;
        }
    }
}
