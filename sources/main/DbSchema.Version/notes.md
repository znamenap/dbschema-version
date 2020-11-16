## Development Notes

# Design Notes
- Upgrade or Downgrade step is differenitated by column value Upgrade.
  If it is Upgrade = 0 it means downgrade step.

**Expected scenario:**
- A developer maintains list of records representing the steps to be registered into `[schema_version].[step]`
  per order of <database schema name, application name and version>.
- Application developer must grant execute permission to the upgrade or downgrade step procedure to user [schema_version_writer].
- When the upgrade have to happen, the developer ought
  to insert the records into the steps table to represent desired upgrade
  or downgrade scenario(s).
- When a developer invokes `[schema_version].[invoke_version_change]` then the system
  executes necessary steps to get to the version as requested. It performs
  the stored procedures invocation in the sequence of the steps ordered by `sequence`
  column up on to the the last step with the version matching the requested version.
  Depending on the actual version and the target version determines if it performs upgrade or downgrade.


## Implementation Points
PENDING:
- Add the script to build the gaint change script in one transaction.
- Add participants to join building the change script.
- Make single build script for whole to get up to the nuget nupkg in output.
- Consider transactionality in procedures or wheather to assume external transaction or none.
- Make auditing to who, when and what has been version changed.

COMPLETED:
- Version parsing
- Version registry per application and schema name.
- Downgrade step registry per application and schema name.
- Upgrade step registry per application and schema name.
- Make step change invocation via procedure.
- Refactor step invocation into dedicated stored procedure.
- Added roles for reade, writer and owner.
- Added permissions per each db object.
- Added existence check for procedure of the step while registering it.
- Restructure the repo to use higher level folder for configuration stuff.
