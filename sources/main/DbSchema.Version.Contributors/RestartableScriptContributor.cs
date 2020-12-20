using Microsoft.SqlServer.Dac.Deployment;
using Microsoft.SqlServer.Dac.Extensibility;
using Microsoft.SqlServer.Dac.Model;
using Microsoft.SqlServer.TransactSql.ScriptDom;

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace DbSchema.Version.Contributors
{
    /// <summary>
    /// This deployment contributor modifies a deployment plan by adding if statements
    /// to the existing batches in order to make a deployment script able to be rerun to completion
    /// if an error is encountered during execution
    /// </summary>
    [ExportDeploymentPlanModifier("DbSchema.Version.Contributors.RestartableScript", "1.0")]
    public class RestartableScriptContributor : DeploymentPlanModifier
    {
        private const string BatchIdColumnName = "BatchId";
        private const string DescriptionColumnName = "Description";

        private const string CompletedBatchesVariableName = "CompletedBatches";
        private const string CompletedBatchesVariable = "$(CompletedBatches)";
        private const string CompletedBatchesSqlCmd = @":setvar " + CompletedBatchesVariableName + " __completedBatches_{0}_{1}";
        private const string TotalBatchCountSqlCmd = @":setvar TotalBatchCount {0}";
        private const string CreateCompletedBatchesTable = @"
if OBJECT_ID(N'tempdb.dbo." + CompletedBatchesVariable + @"', N'U') is null
begin
    use tempdb
    create table [dbo].[$(CompletedBatches)] (
        BatchId int primary key,
        Description nvarchar(300)
    );
    use [$(DatabaseName)]
end
";
        private const string DropCompletedBatchesTable = @"
if OBJECT_ID(N'tempdb.dbo." + CompletedBatchesVariable + @"', N'U') is not null
begin
    use tempdb
    drop table [dbo].[$(CompletedBatches)];
    use [$(DatabaseName)]
end
";

        /// <summary>
        /// You override the OnExecute method to do the real work of the contributor.
        /// </summary>
        /// <param name="context">The deployment plan contributor context instance.</param>
        protected override void OnExecute(DeploymentPlanContributorContext context)
        {
            PublishMessage(new ExtensibilityError("Executing RestartableScriptContributor", Severity.Message));

            // Obtain the first step in the Plan from the provided context
            DeploymentStep nextStep = context.PlanHandle.Head;
            int batchId = 0;
            BeginPreDeploymentScriptStep beforePreDeploy = null;

            // Loop through all steps in the deployment plan
            while (nextStep != null)
            {
                // Increment the step pointer, saving both the current and next steps
                DeploymentStep currentStep = nextStep;
                nextStep = currentStep.Next;

                // Add additional step processing here
                // Look for steps that mark the pre/post deployment scripts
                // These steps will always be in the deployment plan even if the
                // user's project does not have a pre/post deployment script
                if (currentStep is BeginPreDeploymentScriptStep)
                {
                    // This step marks the beginning of the predeployment script.
                    // Save the step and move on.
                    beforePreDeploy = (BeginPreDeploymentScriptStep)currentStep;
                    continue;
                }
                if (currentStep is BeginPostDeploymentScriptStep)
                {
                    // This is the step that marks the beginning of the post deployment script.
                    // We do not continue processing after this point.
                    break;
                }
                if (currentStep is SqlPrintStep)
                {
                    // We do not need to put if statements around these
                    continue;
                }

                // if we have not yet found the beginning of the pre-deployment script steps,
                // skip to the next step.
                if (beforePreDeploy == null)
                {
                    // We only surround the "main" statement block with conditional
                    // statements
                    continue;
                }

                // Determine if this is a step that we need to surround with a conditional statement
                DeploymentScriptDomStep domStep = currentStep as DeploymentScriptDomStep;
                if (domStep == null)
                {
                    // This step is not a step that we know how to modify,
                    // so skip to the next step.
                    continue;
                }

                TSqlScript script = domStep.Script as TSqlScript;
                if (script == null)
                {
                    // The script dom step does not have a script with batches - skip
                    continue;
                }

                // Loop through all the batches in the script for this step.  All the statements
                // in the batch will be enclosed in an if statement that will check the
                // table to ensure that the batch has not already been executed
                TSqlObject sqlObject;
                string stepDescription;
                GetStepInfo(domStep, out stepDescription, out sqlObject);
                int batchCount = script.Batches.Count;

                for (int batchIndex = 0; batchIndex < batchCount; batchIndex++)
                {
                    // Add batch processing here
                    // Create the if statement that will contain the batch's contents
                    IfStatement ifBatchNotExecutedStatement = CreateIfNotExecutedStatement(batchId);
                    BeginEndBlockStatement statementBlock = new BeginEndBlockStatement();
                    ifBatchNotExecutedStatement.ThenStatement = statementBlock;
                    statementBlock.StatementList = new StatementList();

                    TSqlBatch batch = script.Batches[batchIndex];
                    int statementCount = batch.Statements.Count;

                    // Loop through all statements in the batch, embedding those in an sp_execsql
                    // statement that must be handled this way (schemas, stored procedures,
                    // views, functions, and triggers).
                    for (int statementIndex = 0; statementIndex < statementCount; statementIndex++)
                    {
                        // Add additional statement processing here
                        TSqlStatement smnt = batch.Statements[statementIndex];

                        if (IsStatementEscaped(sqlObject))
                        {
                            // "escape" this statement by embedding it in a sp_executesql statement
                            string statementScript;
                            domStep.ScriptGenerator.GenerateScript(smnt, out statementScript);
                            ExecuteStatement spExecuteSql = CreateExecuteSql(statementScript);
                            smnt = spExecuteSql;
                        }

                        statementBlock.StatementList.Statements.Add(smnt);
                    }

                    // Add an insert statement to track that all the statements in this
                    // batch were executed.  Turn on nocount to improve performance by
                    // avoiding row inserted messages from the server
                    string batchDescription = string.Format(CultureInfo.InvariantCulture,
                        "{0} batch {1}", stepDescription, batchIndex);

                    PredicateSetStatement noCountOff = new PredicateSetStatement();
                    noCountOff.IsOn = false;
                    noCountOff.Options = SetOptions.NoCount;

                    PredicateSetStatement noCountOn = new PredicateSetStatement();
                    noCountOn.IsOn = true;
                    noCountOn.Options = SetOptions.NoCount;
                    InsertStatement batchCompleteInsert = CreateBatchCompleteInsert(batchId, batchDescription);
                    statementBlock.StatementList.Statements.Add(noCountOn);
                    statementBlock.StatementList.Statements.Add(batchCompleteInsert);
                    statementBlock.StatementList.Statements.Add(noCountOff);

                    // Remove all the statements from the batch (they are now in the if block) and add the if statement
                    // as the sole statement in the batch
                    batch.Statements.Clear();
                    batch.Statements.Add(ifBatchNotExecutedStatement);

                    // Next batch
                    batchId++;
                }
            }

            // if we found steps that required processing, set up a temporary table to track the work that you are doing
            if (beforePreDeploy != null)
            {
                // Add additional post-processing here
                // Declare a SqlCmd variables.
                //
                // CompletedBatches variable - defines the name of the table in tempdb that will track
                // all the completed batches.  The temporary table's name has the target database name and
                // a guid embedded in it so that:
                // * Multiple deployment scripts targeting different DBs on the same server
                // * Failed deployments with old tables do not conflict with more recent deployments
                //
                // TotalBatchCount variable - the total number of batches surrounded by if statements.  Using this
                // variable pre/post deployment scripts can also use the CompletedBatches table to make their
                // script rerunnable if there is an error during execution
                StringBuilder sqlcmdVars = new StringBuilder();
                sqlcmdVars.AppendFormat(CultureInfo.InvariantCulture, CompletedBatchesSqlCmd,
                    context.Options.TargetDatabaseName, Guid.NewGuid().ToString("D"));
                sqlcmdVars.AppendLine();
                sqlcmdVars.AppendFormat(CultureInfo.InvariantCulture, TotalBatchCountSqlCmd, batchId);

                DeploymentScriptStep completedBatchesSetVarStep = new DeploymentScriptStep(sqlcmdVars.ToString());
                base.AddBefore(context.PlanHandle, beforePreDeploy, completedBatchesSetVarStep);

                // Create the temporary table we will use to track the work that we are doing
                DeploymentScriptStep createStatusTableStep = new DeploymentScriptStep(CreateCompletedBatchesTable);
                base.AddBefore(context.PlanHandle, beforePreDeploy, createStatusTableStep);
            }

            // Cleanup and drop the table
            DeploymentScriptStep dropStep = new DeploymentScriptStep(DropCompletedBatchesTable);
            base.AddAfter(context.PlanHandle, context.PlanHandle.Tail, dropStep);
        }

        /// <summary>
        /// The CreateExecuteSql method "wraps" the provided statement script in an "sp_executesql" statement
        /// Examples of statements that must be so wrapped include: stored procedures, views, and functions
        /// </summary>
        private static ExecuteStatement CreateExecuteSql(string statementScript)
        {
            // define a new Exec statement
            ExecuteStatement executeSp = new ExecuteStatement();
            ExecutableProcedureReference spExecute = new ExecutableProcedureReference();
            executeSp.ExecuteSpecification = new ExecuteSpecification { ExecutableEntity = spExecute };

            // define the name of the procedure that you want to execute, in this case sp_executesql
            SchemaObjectName procName = new SchemaObjectName();
            procName.Identifiers.Add(CreateIdentifier("sp_executesql", QuoteType.NotQuoted));
            ProcedureReference procRef = new ProcedureReference { Name = procName };

            spExecute.ProcedureReference = new ProcedureReferenceName { ProcedureReference = procRef };

            // add the script parameter, constructed from the provided statement script
            ExecuteParameter scriptParam = new ExecuteParameter();
            spExecute.Parameters.Add(scriptParam);
            // ORIGINAL: scriptParam.ParameterValue = new StringLiteral { Value = statementScript };
            scriptParam.ParameterValue = new StringLiteral { IsNational = true, Value = statementScript };
            // ORIGINAL: scriptParam.Variable = new VariableReference { Name = "@stmt" };
            scriptParam.Variable = new VariableReference { Name = "@statement" };
            return executeSp;
        }

        /// <summary>
        /// The CreateIdentifier method returns a Identifier with the specified value and quoting type
        /// </summary>
        private static Identifier CreateIdentifier(string value, QuoteType quoteType)
        {
            return new Identifier { Value = value, QuoteType = quoteType };
        }

        /// <summary>
        /// The CreateCompletedBatchesName method creates the name that will be inserted
        /// into the temporary table for a batch.
        /// </summary>
        private static SchemaObjectName CreateCompletedBatchesName()
        {
            SchemaObjectName name = new SchemaObjectName();
            name.Identifiers.Add(CreateIdentifier("tempdb", QuoteType.SquareBracket));
            name.Identifiers.Add(CreateIdentifier("dbo", QuoteType.SquareBracket));
            name.Identifiers.Add(CreateIdentifier(CompletedBatchesVariable, QuoteType.SquareBracket));
            return name;
        }

        /// <summary>
        /// Helper method that determins whether the specified statement needs to
        /// be escaped
        /// </summary>
        /// <param name="sqlObject"></param>
        /// <returns></returns>
        private static bool IsStatementEscaped(TSqlObject sqlObject)
        {
            HashSet<ModelTypeClass> escapedTypes = new HashSet<ModelTypeClass>
            {
                Schema.TypeClass,
                Procedure.TypeClass,
                View.TypeClass,
                TableValuedFunction.TypeClass,
                ScalarFunction.TypeClass,
                DatabaseDdlTrigger.TypeClass,
                DmlTrigger.TypeClass,
                ServerDdlTrigger.TypeClass
            };
            return escapedTypes.Contains(sqlObject.ObjectType);
        }

        /// <summary>
        /// Helper method that creates an INSERT statement to track a batch being completed
        /// </summary>
        /// <param name="batchId"></param>
        /// <param name="batchDescription"></param>
        /// <returns></returns>
        private static InsertStatement CreateBatchCompleteInsert(int batchId, string batchDescription)
        {
            InsertStatement insert = new InsertStatement();
            NamedTableReference batchesCompleted = new NamedTableReference();
            insert.InsertSpecification = new InsertSpecification();
            insert.InsertSpecification.Target = batchesCompleted;
            batchesCompleted.SchemaObject = CreateCompletedBatchesName();

            // Build the columns inserted into
            ColumnReferenceExpression batchIdColumn = new ColumnReferenceExpression();
            batchIdColumn.MultiPartIdentifier = new MultiPartIdentifier();
            batchIdColumn.MultiPartIdentifier.Identifiers.Add(CreateIdentifier(BatchIdColumnName, QuoteType.NotQuoted));

            ColumnReferenceExpression descriptionColumn = new ColumnReferenceExpression();
            descriptionColumn.MultiPartIdentifier = new MultiPartIdentifier();
            descriptionColumn.MultiPartIdentifier.Identifiers.Add(CreateIdentifier(DescriptionColumnName, QuoteType.NotQuoted));

            insert.InsertSpecification.Columns.Add(batchIdColumn);
            insert.InsertSpecification.Columns.Add(descriptionColumn);

            // Build the values inserted
            ValuesInsertSource valueSource = new ValuesInsertSource();
            insert.InsertSpecification.InsertSource = valueSource;

            RowValue values = new RowValue();
            values.ColumnValues.Add(new IntegerLiteral { Value = batchId.ToString() });
            values.ColumnValues.Add(new StringLiteral { Value = batchDescription });
            valueSource.RowValues.Add(values);

            return insert;
        }

        /// <summary>
        /// This is a helper method that generates an if statement that checks the batches executed
        /// table to see if the current batch has been executed.  The if statement will look like this
        ///
        /// if not exists(select 1 from [tempdb].[dbo].[$(CompletedBatches)]
        ///                where BatchId = batchId)
        /// begin
        /// end
        /// </summary>
        /// <param name="batchId"></param>
        /// <returns></returns>
        private static IfStatement CreateIfNotExecutedStatement(int batchId)
        {
            // Create the exists/select statement
            ExistsPredicate existsExp = new ExistsPredicate();
            ScalarSubquery subQuery = new ScalarSubquery();
            existsExp.Subquery = subQuery;

            subQuery.QueryExpression = new QuerySpecification
            {
                SelectElements =
        {
            new SelectScalarExpression  { Expression = new IntegerLiteral { Value ="1" } }
        },
                FromClause = new FromClause
                {
                    TableReferences =
                {
                    new NamedTableReference() { SchemaObject = CreateCompletedBatchesName() }
                }
                },
                WhereClause = new WhereClause
                {
                    SearchCondition = new BooleanComparisonExpression
                    {
                        ComparisonType = BooleanComparisonType.Equals,
                        FirstExpression = new ColumnReferenceExpression
                        {
                            MultiPartIdentifier = new MultiPartIdentifier
                            {
                                Identifiers = { CreateIdentifier(BatchIdColumnName, QuoteType.SquareBracket) }
                            }
                        },
                        SecondExpression = new IntegerLiteral { Value = batchId.ToString() }
                    }
                }
            };

            // Put together the rest of the statement
            IfStatement ifNotExists = new IfStatement
            {
                Predicate = new BooleanNotExpression
                {
                    Expression = existsExp
                }
            };

            return ifNotExists;
        }

        /// <summary>
        /// Helper method that generates a useful description of the step.
        /// </summary>
        private static void GetStepInfo(
            DeploymentScriptDomStep domStep,
            out string stepDescription,
            out TSqlObject element)
        {
            element = null;

            // figure out what type of step we've got, and retrieve
            // either the source or target element.
            if (domStep is CreateElementStep)
            {
                element = ((CreateElementStep)domStep).SourceElement;
            }
            else if (domStep is AlterElementStep)
            {
                element = ((AlterElementStep)domStep).SourceElement;
            }
            else if (domStep is DropElementStep)
            {
                element = ((DropElementStep)domStep).TargetElement;
            }

            // construct the step description by concatenating the type and the fully qualified
            // name of the associated element.
            string stepTypeName = domStep.GetType().Name;
            if (element != null)
            {
                string elementName = GetElementName(element);

                stepDescription = string.Format(CultureInfo.InvariantCulture, "{0} {1}",
                    stepTypeName, elementName);
            }
            else
            {
                // if the step has no associated element, just use the step type as the description
                stepDescription = stepTypeName;
            }
        }

        private static string GetElementName(TSqlObject element)
        {
            StringBuilder name = new StringBuilder();
            if (element.Name.HasExternalParts)
            {
                foreach (string part in element.Name.ExternalParts)
                {
                    if (name.Length > 0)
                    {
                        name.Append('.');
                    }
                    name.AppendFormat("[{0}]", part);
                }
            }

            foreach (string part in element.Name.Parts)
            {
                if (name.Length > 0)
                {
                    name.Append('.');
                }
                name.AppendFormat("[{0}]", part);
            }

            return name.ToString();
        }
    }
}