using Microsoft.Build.Framework;
using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Extensibility;
using Microsoft.SqlServer.Dac.Model;

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace DbSchema.Version.Contributors
{
    /// <summary>
    /// Build contributor
    /// A BuildContributor that generates statistics about a model and saves this to the output directory.
    /// Will only run if a "GenerateModelStatistics=true" contributor argument is set in the project file, or a targets file.
    /// Statistics can be sorted by "none, "name" or "value", with "none" being the default sort behavior.
    ///
    /// To set contributor arguments in a project file, add the following:
    ///
    /// <PropertyGroup>
    ///     <ContributorArguments Condition="'$(Configuration)' == 'Debug'">
    /// $(ContributorArguments);ModelStatistics.GenerateModelStatistics=true;ModelStatistics.SortModelStatisticsBy="name";
    ///     </ContributorArguments>
    /// <PropertyGroup>
    ///
    /// This will generate model statistics when building in Debug mode only - remove the condition to generate in all build modes.
    /// </summary>
    [ExportBuildContributor("DbSchema.Version.Contributors.ModelStatistics", "1.0")]
    public class ModelStatisticsContributor : BuildContributor
    {
        public const string GenerateModelStatistics = "DbSchema.Version.Contributors.ModelStatistics.GenerateModelStatistics";
        public const string SortModelStatisticsBy = "DbSchema.Version.Contributors.ModelStatistics.SortModelStatisticsBy";
        public const string OutDir = "DbSchema.Version.Contributors.ModelStatistics.OutDir";
        public const string ModelStatisticsFilename = "DbSchema.Version.Contributors.ModelStatistics.xml";
        private enum SortBy { None, Name, Value };
        private static Dictionary<string, SortBy> SortByMap = new Dictionary<string, SortBy>(StringComparer.OrdinalIgnoreCase)
        {
            { "none", SortBy.None },
            { "name", SortBy.Name },
            { "value", SortBy.Value },
        };

        private SortBy _sortBy = SortBy.None;

        /// <summary>
        /// Override the OnExecute method to perform actions when you build a database project.
        /// </summary>
        protected override void OnExecute(BuildContributorContext context, IList<ExtensibilityError> errors)
        {
            // handle related arguments, passed in as part of
            // the context information.
            bool generateModelStatistics;
            ParseArguments(context.Arguments, errors, out generateModelStatistics);

            StringBuilder statisticsMsg = new StringBuilder();

            statisticsMsg.AppendLine("Arguments passed:");
            context.Arguments.Where(kvp => kvp.Value != null)
                .Select(KeyValuePairToString).ToList()
                .ForEach(s => statisticsMsg.AppendLine($"  {s}"));
            statisticsMsg.AppendLine();
            statisticsMsg.AppendLine("Build properties:");
            context.BuildProperties.Where(kvp => kvp.Value != null)
                .Select(KeyValuePairToString).ToList()
                .ForEach(s => statisticsMsg.AppendLine($"  {s}"));
            errors.Add(new ExtensibilityError(statisticsMsg.ToString(), Severity.Message));
            statisticsMsg.Length = 0;

            // Only generate statistics if requested to do so
            if (generateModelStatistics)
            {
                // First, output model-wide information, such
                // as the type of database schema provider (DSP)
                // and the collation.
                statisticsMsg.AppendLine(" ")
                             .AppendLine("Model Statistics:")
                             .AppendLine("===")
                             .AppendLine(" ");
                errors.Add(new ExtensibilityError(statisticsMsg.ToString(), Severity.Message));

                var model = context.Model;

                // Start building up the XML that will later
                // be serialized.
                var xRoot = new XElement("ModelStatistics");

                SummarizeModelInfo(model, xRoot, errors);

                // First, count the elements that are contained
                // in this model.
                IList<TSqlObject> elements = model.GetObjects(DacQueryScopes.UserDefined).ToList();
                Summarize(elements, element => element.ObjectType.Name, "UserDefinedElements", xRoot, errors);

                // Now, count the elements that are defined in
                // another model. Examples include built-in types,
                // roles, filegroups, assemblies, and any
                // referenced objects from another database.
                elements = model.GetObjects(DacQueryScopes.BuiltIn | DacQueryScopes.SameDatabase | DacQueryScopes.System).ToList();
                Summarize(elements, element => element.ObjectType.Name, "OtherElements", xRoot, errors);

                // Now, count the number of each type
                // of relationship in the model.
                SurveyRelationships(model, xRoot, errors);

                // Determine where the user wants to save
                // the serialized XML file.
                string outDir;
                if (context.Arguments.TryGetValue(OutDir, out outDir) == false)
                {
                    outDir = ".";
                }
                string filePath = Path.Combine(outDir, ModelStatisticsFilename);
                // Save the XML file and tell the user
                // where it was saved.
                xRoot.Save(filePath);
                ExtensibilityError resultArg = new ExtensibilityError("Statistsics of the model was saved to " + filePath, Severity.Message);
                errors.Add(resultArg);
            }
        }

        private static string KeyValuePairToString<T>(KeyValuePair<string, T> kvp)
        {
            if (kvp.Value is ITaskItem[] taskItems) {
                return taskItems.ToList().Aggregate(
                    new StringBuilder($"{kvp.Key}="), (sb, ti) => sb.Append($"{ti.ItemSpec};"), sb => sb.ToString());
            }
            return $"{kvp.Key}={kvp.Value}";
        }

        /// <summary>
        /// Examine the arguments provided by the user
        /// to determine if model statistics should be generated
        /// and, if so, how the results should be sorted.
        /// </summary>
        private void ParseArguments(IDictionary<string, string> arguments, IList<ExtensibilityError> errors, out bool generateModelStatistics)
        {
            // By default, we don't generate model statistics
            generateModelStatistics = false;

            // see if the user provided the GenerateModelStatistics
            // option and if so, what value was it given.
            string valueString;
            arguments.TryGetValue(GenerateModelStatistics, out valueString);
            if (string.IsNullOrWhiteSpace(valueString) == false)
            {
                if (bool.TryParse(valueString, out generateModelStatistics) == false)
                {
                    generateModelStatistics = false;

                    // The value was not valid from the end user
                    ExtensibilityError invalidArg = new ExtensibilityError(
                        GenerateModelStatistics + "=" + valueString + " was not valid.  It can be true or false", Severity.Error);
                    errors.Add(invalidArg);
                    return;
                }
            }

            // Only worry about sort order if the user requested
            // that we generate model statistics.
            if (generateModelStatistics)
            {
                // see if the user provided the sort option and
                // if so, what value was provided.
                arguments.TryGetValue(SortModelStatisticsBy, out valueString);
                if (string.IsNullOrWhiteSpace(valueString) == false)
                {
                    SortBy sortBy;
                    if (SortByMap.TryGetValue(valueString, out sortBy))
                    {
                        _sortBy = sortBy;
                    }
                    else
                    {
                        // The value was not valid from the end user
                        ExtensibilityError invalidArg = new ExtensibilityError(
                            SortModelStatisticsBy + "=" + valueString + " was not valid.  It can be none, name, or value", Severity.Error);
                        errors.Add(invalidArg);
                    }
                }
            }
        }

        /// <summary>
        /// Retrieve the database schema provider for the
        /// model and the collation of that model.
        /// Results are output to the console and added to the XML
        /// being constructed.
        /// </summary>
        private static void SummarizeModelInfo(TSqlModel model, XElement xContainer, IList<ExtensibilityError> errors)
        {
            // use a Dictionary to accumulate the information
            // that will later be output.
            var info = new Dictionary<string, string>();

            // Two things of interest: the database schema
            // provider for the model, and the language id and
            // case sensitivity of the collation of that
            // model
            info.Add("Version", model.Version.ToString());

            TSqlObject options = model.GetObjects(DacQueryScopes.UserDefined, DatabaseOptions.TypeClass).FirstOrDefault();
            if (options != null)
            {
                info.Add("Collation", options.GetProperty<string>(DatabaseOptions.Collation));
            }

            // Output the accumulated information and add it to
            // the XML.
            OutputResult("Basic model info", info, xContainer, errors);
        }

        /// <summary>
        /// For a provided list of model elements, count the number
        /// of elements for each class name, sorted as specified
        /// by the user.
        /// Results are output to the console and added to the XML
        /// being constructed.
        /// </summary>
        private void Summarize<T>(IList<T> set, Func<T, string> groupValue, string category, XElement xContainer, IList<ExtensibilityError> errors)
        { // Use a Dictionary to keep all summarized information
            var statistics = new Dictionary<string, int>();

            // For each element in the provided list,
            // count items based on the specified grouping
            var groups =
                from item in set
                group item by groupValue(item) into g
                select new { g.Key, Count = g.Count() };

            // order the groups as requested by the user
            if (this._sortBy == SortBy.Name)
            {
                groups = groups.OrderBy(group => group.Key);
            }
            else if (this._sortBy == SortBy.Value)
            {
                groups = groups.OrderBy(group => group.Count);
            }

            // build the Dictionary of accumulated statistics
            // that will be passed along to the OutputResult method.
            foreach (var item in groups)
            {
                statistics.Add(item.Key, item.Count);
            }

            statistics.Add("subtotal", set.Count);
            statistics.Add("total items", groups.Count());

            // output the results, and build up the XML
            OutputResult(category, statistics, xContainer, errors);
        }

        /// <summary>
        /// Iterate over all model elements, counting the
        /// styles and types for relationships that reference each
        /// element
        /// Results are output to the console and added to the XML
        /// being constructed.
        /// </summary>
        private static void SurveyRelationships(TSqlModel model, XElement xContainer, IList<ExtensibilityError> errors)
        {
            // get a list that contains all elements in the model
            var elements = model.GetObjects(DacQueryScopes.All);
            // We are interested in all relationships that
            // reference each element.
            var entries =
                from element in elements
                from entry in element.GetReferencedRelationshipInstances(DacExternalQueryScopes.All)
                select entry;

            // initialize our counting buckets
            var composing = 0;
            var hierachical = 0;
            var peer = 0;

            // process each relationship, adding to the
            // appropriate bucket for style and type.
            foreach (var entry in entries)
            {
                switch (entry.Relationship.Type)
                {
                    case RelationshipType.Composing:
                        ++composing;
                        break;
                    case RelationshipType.Hierarchical:
                        ++hierachical;
                        break;
                    case RelationshipType.Peer:
                        ++peer;
                        break;
                    default:
                        break;
                }
            }

            // build a dictionary of data to pass along
            // to the OutputResult method.
            var stat = new Dictionary<string, int>
            {
                {"Composing", composing},
                {"Hierarchical", hierachical},
                {"Peer", peer},
                {"subtotal", entries.Count()}
            };

            OutputResult("Relationships", stat, xContainer, errors);
        }

        /// <summary>
        /// Performs the actual output for this contributor,
        /// writing the specified set of statistics, and adding any
        /// output information to the XML being constructed.
        /// </summary>
        private static void OutputResult<T>(string category, Dictionary<string, T> statistics, XElement xContainer, IList<ExtensibilityError> errors)
        {
            var maxLen = statistics.Max(stat => stat.Key.Length) + 2;
            var format = string.Format("{{0, {0}}}: {{1}}", maxLen);

            StringBuilder resultMessage = new StringBuilder();
            //List<ExtensibilityError> args = new List<ExtensibilityError>();
            resultMessage.AppendLine(category);
            resultMessage.AppendLine("-----------------");

            // Remove any blank spaces from the category name
            var xCategory = new XElement(category.Replace(" ", ""));
            xContainer.Add(xCategory);

            foreach (var item in statistics)
            {
                //Console.WriteLine(format, item.Key, item.Value);
                var entry = string.Format(format, item.Key, item.Value);
                resultMessage.AppendLine(entry);
                // Replace any blank spaces in the element key with
                // underscores.
                xCategory.Add(new XElement(item.Key.Replace(' ', '_'), item.Value));
            }
            resultMessage.AppendLine(" ");
            errors.Add(new ExtensibilityError(resultMessage.ToString(), Severity.Message));
        }
    }
}
