using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Model
{
    public class DeploymentStepEnumerable : IEnumerable<DeploymentStep>
    {
        private readonly DeploymentStep firstStep;

        public static IEnumerable<DeploymentStep> AsEnumerable(DeploymentStep firstStep)
        {
            return new DeploymentStepEnumerable(firstStep);
        }

        public DeploymentStepEnumerable(DeploymentStep firstStep)
        {
            this.firstStep = firstStep ?? throw new ArgumentNullException(nameof(firstStep));
        }

        public IEnumerator<DeploymentStep> GetEnumerator()
        {
            return new DeploymentStepEnumerator(firstStep);
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }

        private class DeploymentStepEnumerator : IEnumerator<DeploymentStep>
        {
            private readonly DeploymentStep firstStep;
            private DeploymentStep current;
            private bool started;

            public DeploymentStepEnumerator(DeploymentStep firstStep)
            {
                this.firstStep = firstStep ?? throw new ArgumentNullException(nameof(firstStep));
            }

            public void Dispose()
            {
            }

            /// <summary>Advances the enumerator to the next element of the collection.</summary>
            /// <returns>true if the enumerator was successfully advanced to the next element; false if the enumerator has passed the end of the collection.</returns>
            /// <exception cref="T:System.InvalidOperationException">The collection was modified after the enumerator was created. </exception>
            public bool MoveNext()
            {
                if (!started)
                {
                    current = firstStep;
                    started = true;
                }
                else
                {
                    current = current.Next;
                }
                return current != null;
            }

            public void Reset()
            {
                started = false;
            }

            /// <summary>Gets the element in the collection at the current position of the enumerator.</summary>
            /// <returns>The element in the collection at the current position of the enumerator.</returns>
            public DeploymentStep Current => current;

            object IEnumerator.Current => Current;
        }
    }
}
