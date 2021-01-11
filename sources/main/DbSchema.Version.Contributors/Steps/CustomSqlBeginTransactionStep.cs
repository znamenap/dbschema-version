using System.Collections.Generic;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Steps
{
    /// <summary>
    /// Adds the custom SqlBeginTransactionStep because cannot add the regular from the framework.
    /// </summary>
    public class CustomSqlBeginTransactionStep : DeploymentStep
    {
        /// <inheritdoc />
        public override IList<string> GenerateTSQL()
        {
            return new []
            {
@"
IF (SELECT OBJECT_ID('tempdb..#tmpErrors')) IS NOT NULL DROP TABLE #tmpErrors
GO
CREATE TABLE #tmpErrors (Error int)
GO
SET XACT_ABORT ON
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
GO
BEGIN TRANSACTION
"
            };
        }
    }
}
