using System.Collections.Generic;
using System.Linq;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Model
{
    public static class DeploymentStepExtensions
    {
        public static IEnumerable<DeploymentStep> AsEnumerable(this DeploymentStep step)
        {
            return DeploymentStepEnumerable.AsEnumerable(step);
        }

        public static IEnumerable<T> NextOfType<T>(this DeploymentStep step) where T : DeploymentStep
        {
            return DeploymentStepEnumerable.AsEnumerable(step).OfType<T>();
        }
    }
}