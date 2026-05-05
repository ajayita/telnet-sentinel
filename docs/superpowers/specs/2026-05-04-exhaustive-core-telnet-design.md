# Design Spec: Comprehensive Audit Execution

To provide a full "Standard Audit", we will update the `telnet_sentinel` CLI to orchestrate all available probes in the codebase.

## Objective
Transition the CLI from running a single hardcoded probe to executing a sequential suite of all implemented Telnet probes.

## Proposed Probes to Include
The following probes from `lib/probes/` will be executed in order:
1.  **HandshakeProbe**: Verifies initial protocol negotiation (TTYPE).
2.  **AytProbe**: Checks if the server responds to "Are You There" (AYT) commands.
3.  **BinaryModeProbe**: Tests negotiation of TRANSMIT-BINARY mode.
4.  **GmcpProbe**: Validates support for Generic Mud Communication Protocol.
5.  **MccpProbe**: Verifies Mud Client Compression Protocol (zlib).
6.  **MalformedIacProbe**: Tests server resilience against malformed IAC sequences.
7.  **NegotiationLoopProbe**: Checks for potential infinite negotiation loops.

## Implementation Details

### CLI Orchestration (`bin/telnet_sentinel.dart`)
- **Probe Registry**: Create a list or map of all available `Probe` instances.
- **Execution Loop**:
  - Iterate through the probe list.
  - For each probe:
    - Establish a *new* connection (to ensure a clean state for each probe).
    - Run the probe.
    - Collect the `AuditResult`.
    - Close the connection.
- **Error Handling**: Catch exceptions per-probe to ensure one failing probe doesn't crash the entire audit.

### Reporting
- The `AuditReport` already supports a list of `AuditResult` objects.
- The summary will accurately reflect the success/failure of the entire suite.

## Verification Plan
1.  **Manual Test**: Run `dart bin/telnet_sentinel.dart 127.0.0.1 -p 2323` and verify all 7 probes appear in the report.
2.  **Regression Check**: Ensure `--json` output still works correctly with multiple results.
3.  **Timeout Verification**: Ensure the audit completes in a reasonable time if some probes timeout.
