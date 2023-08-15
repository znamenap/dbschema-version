using System.Collections.Generic;
using System.Text;
using DbSchema.Version.Contributors.Model;
using Microsoft.SqlServer.Dac.Deployment;

namespace DbSchema.Version.Contributors.Steps
{
    /// <inheritdoc />
    public class DeploySchemaVersionStep : DeploymentStep
    {
        private readonly bool isTransactional;
        private readonly string schemaNameSqlCmdVarName;
        private readonly string applicationNameSqlCmdVarName;
        private readonly string applicationVersionSqlCmdVarName;

        /// <inheritdoc />
        public DeploySchemaVersionStep(bool isTransactional, string schemaNameSqlCmdVarName, string applicationNameSqlCmdVarName, string applicationVersionSqlCmdVarName)
        {
            this.isTransactional = isTransactional;
            this.schemaNameSqlCmdVarName = schemaNameSqlCmdVarName;
            this.applicationNameSqlCmdVarName = applicationNameSqlCmdVarName;
            this.applicationVersionSqlCmdVarName = applicationVersionSqlCmdVarName;
        }

        /// <inheritdoc />
        public override IList<string> GenerateTSQL()
        {
            var builder = new StringBuilder();
            builder.AppendLine(string.Format(@"
if ('$({2})' != 'NULL')
begin
    print 'Transaction count: ' + cast(@@trancount as varchar(10))
    declare @result as int = -1;
    begin try
        declare @version_number [schema_version].[t_version];
        exec @result = [schema_version].[parse_version] @version_text = '$({2})'
                                        , @weight_base = 1000
                                        , @version_number = @version_number output ;  -- decimal
        if (@@error <> 0 or @result < 0)
        begin
            print 'ERROR: parse_version failed. Cause: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ')';
        end
        else
        begin
            exec @result = [schema_version].[invoke_version_change]
                  @schema_name = '$({0})'
                , @application_name = '$({1})'
                , @version = @version_number
            if (@@error <> 0 or @result < 0)
            begin
                print 'ERROR: invoke_version_change failed. Cause: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ')';
            end
        end
    end try
    begin catch
        print 'ERROR: invoke_version_change failed. Cause: ' + error_message() + '(Severity=' + cast(error_severity() as varchar(256)) + ')';
    end catch
", schemaNameSqlCmdVarName, applicationNameSqlCmdVarName, applicationVersionSqlCmdVarName));

            if (isTransactional)
            {
                builder.AppendLine("    if (@@error <> 0 or @result < 0) and @@trancount > 0 begin rollback transaction; end");
                builder.AppendLine("    if @@trancount = 0 begin insert into #tmperrors(error) values (1); begin transaction; end");
            }

            builder.AppendLine("end");

            return new List<string> {builder.ToString()};
        }
    }
}