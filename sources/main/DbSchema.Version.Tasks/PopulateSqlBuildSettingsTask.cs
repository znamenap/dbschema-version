using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace DbSchema.Version.Tasks
{
    /// <summary>
    /// This is very nasty hack in order to prevent contributor's binaries installation into
    /// program files space on the machines (build servers) where the administrative privileges
    /// are not possible and in most cases built from an image without an option to amend with
    /// such an highly customized binaries.
    /// </summary>
    public sealed class PopulateSqlBuildSettingsTask : Task
    {
        /// <summary>
        /// Represents the list of contributor paths to look up through.
        /// </summary>
        public ITaskItem[] DeploymentContributorPaths { get; set; } = new ITaskItem[0];

        /// <inheritdoc />
        public override bool Execute()
        {
            try
            {
                var assemblies = AppDomain.CurrentDomain.GetAssemblies().ToList();
                var ambientSettingType = assemblies
                    .SelectMany(asm => asm.GetTypes())
                    .FirstOrDefault(t => t.Name == "AmbientSettings");

                if (ambientSettingType != null)
                {
                    var defaultSettingsPropertyType = ambientSettingType.GetProperty("DefaultSettings");
                    if (defaultSettingsPropertyType != null)
                    {
                        var ambientDataObject = defaultSettingsPropertyType.GetValue(null);
                        if (ambientDataObject != null)
                        {
                            var ambientDataType = ambientDataObject.GetType();

                            var populateSettingsMethodInfo = ambientDataType.GetMethod("PopulateSettings");
                            if (populateSettingsMethodInfo != null)
                            {
                                var values = DeploymentContributorPaths.Select(p => p.ItemSpec)
                                    .Select(path => File.Exists(path)? Path.GetDirectoryName(path) : path)
                                    .ToArray();
                                var settings = new Dictionary<string, object>
                                {
                                    {"DeploymentContributorPaths", values}
                                };
                                populateSettingsMethodInfo.Invoke(ambientDataObject, new object[] {settings});
                                return true;
                            }
                        }
                    }
                }
                else
                {
                    Log.LogWarning("There is no AmbientSettings type available from {0} assemblies.",
                            assemblies.Count);
                    foreach (var assembly in assemblies)
                    {
                        Log.LogMessage("  assembly: {0}", assembly.FullName);
                    }
                }
            }
            catch (ReflectionTypeLoadException e)
            {
                Log.LogError(e.ToString());
                e.LoaderExceptions.ToList().ForEach(le => Log.LogError(le.ToString()));
            }
            catch (Exception e)
            {
                Log.LogError(e.ToString());
            }

            return false;
        }
    }
}
