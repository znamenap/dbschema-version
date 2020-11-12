## Development Notes

# Design Notes
- Upgrade or Downgrade step is differenitated by column value Upgrade. 
  If it is Upgrade = 0 it means downgrade step.

**Expected scenario:**
- A developer maintains list of records representing the steps to be registered into `[schema_version].[step]` per order of <database schema name, application name and version>.
- When the upgrade have to happen, the developer ought
  to insert the records into the steps table to represent desired upgrade 
  or downgrade scenario(s).
- When a developer invokes `[schema_version].[invoke_version_change]` then the system
  executes necessary steps to get to the version as requested. It performs
  the stored procedures invocation in the sequence of the steps ordered by `sequence`
  column up on to the the last step with the version matching the requested version. Depending on the actual version and the target version determines if it performs upgrade or downgrade.


## Implementation Points
PENDING:
- Consider transactionality in procedures or wheather to assume external transaction or none.

COMPLETED:
- Version parsing
- Version registry per application and schema name.
- Downgrade step registry per application and schema name.
- Upgrade step registry per application and schema name.
- Make step change invocation via procedure.
- Refactor step invocation into dedicated stored procedure.
