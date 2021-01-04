using System.Collections.Generic;
using System.Linq;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Model
{
    /// <summary>
    /// The extension points to deployment steps.
    /// </summary>
    public static class DeploymentStepExtensions
    {
        /// <summary>
        /// Provides enumerable of deployment steps starting from the provided step.
        /// </summary>
        /// <param name="step">The step where to enumerate from using the next item in the linked list of deployment steps.</param>
        /// <returns>The enumerable instance of deployment steps.</returns>
        public static IEnumerable<DeploymentStep> AsEnumerable(this DeploymentStep step)
        {
            return DeploymentStepEnumerable.AsEnumerable(step);
        }

        /// <summary>
        /// Provides enumerable of deployment steps starting from step which is of the given T type using the OfType extension method.
        /// </summary>
        /// <typeparam name="T">The type of next deployment step from the linked list of deployment steps.</typeparam>
        /// <param name="step">The first deployment step to enumerate from and identify the specific type.</param>
        /// <returns>The enumerable of the next deployment steps of the given type.</returns>
        public static IEnumerable<T> NextOfType<T>(this DeploymentStep step) where T : DeploymentStep
        {
            return DeploymentStepEnumerable.AsEnumerable(step).OfType<T>();
        }
    }
}