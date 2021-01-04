using System;
using System.Collections;
using System.Collections.Generic;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Model
{
    /// <summary>
    /// Represents the enumerable concept of linked list of Deployment Steps.
    /// </summary>
    public sealed class DeploymentStepEnumerable : IEnumerable<DeploymentStep>
    {
        private readonly DeploymentStep firstStep;

        /// <summary>
        /// Returns the Enumerable concept of the next linked list items starting from the provided first step.
        /// </summary>
        /// <param name="firstStep">The first step where to start enumerating the linked list of deployment steps.</param>
        /// <returns>Returns the Enumerable concept of deployment steps.</returns>
        public static IEnumerable<DeploymentStep> AsEnumerable(DeploymentStep firstStep)
        {
            return new DeploymentStepEnumerable(firstStep);
        }

        private DeploymentStepEnumerable(DeploymentStep firstStep)
        {
            this.firstStep = firstStep ?? throw new ArgumentNullException(nameof(firstStep));
        }

        /// <inheritdoc />
        public IEnumerator<DeploymentStep> GetEnumerator()
        {
            return new DeploymentStepEnumerator(firstStep);
        }

        /// <summary>Returns an enumerator that iterates through a collection.</summary>
        /// <returns>An <see cref="T:System.Collections.IEnumerator" /> object that can be used to iterate through the collection.</returns>
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
