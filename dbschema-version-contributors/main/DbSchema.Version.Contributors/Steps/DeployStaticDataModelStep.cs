using System.Collections.Generic;
using System.Text;
using DbSchema.Version.Contributors.Model;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Steps
{
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
            var builder = new StringBuilder();
            foreach (var staticDataModelItem in model.GetItems())
            {
                builder.AppendLine();
                builder.AppendLine($"-- Input File Name: {staticDataModelItem.Item1}");
                builder.AppendLine(staticDataModelItem.Item2.TrimEnd());
                if (isTransactional)
                {
                    builder.AppendLine("go");
                    builder.AppendLine("if @@error <> 0 and @@trancount > 0 begin rollback; end");
                    builder.AppendLine("if @@trancount = 0 begin insert into #tmperrors(error) values (1); begin transaction; end");
                }
                batch.Add(builder.ToString().TrimEnd());
                builder.Length = 0;
            }

            return batch;
        }
    }
}