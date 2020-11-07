## Development Notes

# Design Notes
- Upgrade or Downgrade step is differenitated by column value Upgrade. 
  If it is Upgrade = 0 it means downgrade step.

**Expected scenario:**
- A developer maintains list of records representing the steps to be registered into `[schema_version].[step]` per order of <database schema name, application name and version>.
- When the upgrade have to happen, the developer ought
  to insert the records into the steps table to represent desired upgrade 
  or downgrade scenario(s).
- When a developer invokes `[schema_version].[set_version]` then the system
  proceeds with the necessary steps to get to the version as requested. It performs
  the stored procedures invocation in the sequence of the steps ordered by `sequence`
  column up on to the the last step with the version matching the requested version.

## Implementation Points
PENDING:
- Consider transactionality in procedures or wheather to assume external transaction or none.
- Step invocation for upgrade into `[schema_version].[invoke_version_change]`
- Step invocation for downgrade into `[schema_version].[invoke_version_change]`

COMPLETED:
- Version parsing
- Version registry per application and schema name.
- Downgrade step registry per application and schema name.
- Upgrade step registry per application and schema name.

