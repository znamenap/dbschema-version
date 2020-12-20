using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
using Microsoft.Build.Framework;
using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Extensibility;
using Microsoft.SqlServer.Dac.Model;

namespace DbSchema.Version.Contributors
{
    /// <summary>
    /// This contributor includes all *.data.sql script files marked as None and referenced from the post deployment script.
    /// </summary>
    /// <remarks>
    /// <seealso cref="Microsoft.Data.Tools.Schema.Sql.Deployment.SqlDeploymentPlanGenerator"/>
    /// </remarks>
    [ExportBuildContributor("DbSchema.Version.Contributors.IncludeStaticData", "1.0")]
    public class IncludeStaticDataContributor : BuildContributor
    {
        protected override void OnExecute(BuildContributorContext context, IList<ExtensibilityError> messages)
        {
            base.OnExecute(context, messages);

            string outputPath;
            if (!context.BuildProperties.TryGetValue("SqlTarget", out object sqlTargetObject))
            {
                outputPath = Path.Combine(".", "StaticData.xml");
            }
            else
            {
                var sqlTarget = (ITaskItem) sqlTargetObject;
                var path = sqlTarget.GetMetadata("FullPath");
                outputPath = Path.ChangeExtension(path, ".StaticDataModel.xml");
            }

            var staticDataItems = context.ExtensionFiles.Where(IsStaticDataDeploymentUnit).ToArray();
            if (staticDataItems.Length > 0)
            {
                var staticDataModel = new XDocument(new XElement("StaticDataModel")).Root;
                foreach (var staticDataItem in staticDataItems)
                {
                    var sourceName = staticDataItem.ItemSpec;
                    var path = staticDataItem.GetMetadata("FullPath");
                    var fileContent = File.ReadAllText(path);
                    messages.Add(new ExtensibilityError($"Adding {sourceName} of {fileContent.Length} bytes.",
                        Severity.Message));
                    var staticDataModelItem = new XElement("StaticData",
                        new XAttribute("fullPath", path),
                        new XCData(fileContent));
                    staticDataModel.Add(staticDataModelItem);
                }

                staticDataModel.Save(outputPath);
                messages.Add(new ExtensibilityError($"Static data model persisted at {outputPath}", Severity.Message));
            }
        }

        private static bool IsStaticDataDeploymentUnit(ITaskItem i)
        {
            return i.ItemSpec.EndsWith(".data.sql", StringComparison.OrdinalIgnoreCase);
        }
    }
}
