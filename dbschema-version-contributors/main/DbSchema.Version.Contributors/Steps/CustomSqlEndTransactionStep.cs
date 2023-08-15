using System.Collections.Generic;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Steps
{
    /// <summary>
    /// Adds the custom SqlEndTransactionStep because cannot add the regular from the framework.
    /// </summary>
    public class CustomSqlEndTransactionStep : DeploymentStep
    {
        /// <inheritdoc />
        public override IList<string> GenerateTSQL()
        {
            return new []
            {
@"
IF EXISTS (SELECT * FROM #tmpErrors) ROLLBACK TRANSACTION
GO
IF @@TRANCOUNT>0 BEGIN
PRINT N'The transacted portion of the database update succeeded.'
COMMIT TRANSACTION
END
ELSE PRINT N'The transacted portion of the database update failed.'
GO
DROP TABLE #tmpErrors
"
            };
        }
    }
}
