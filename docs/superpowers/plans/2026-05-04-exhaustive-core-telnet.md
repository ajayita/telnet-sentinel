# Exhaustive Core Telnet Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the CLI to run all available Telnet probes sequentially against a target host.

**Architecture:** The CLI will maintain a list of `Probe` instances. For each probe, it will establish a fresh `RawSocket` connection, wrap it in a `TelnetTransport`, run the probe, collect the result, and close the connection.

**Tech Stack:** Dart, `args` package.

---

### Task 1: Update CLI Imports and Probe Registry

**Files:**
- Modify: `bin/telnet_sentinel.dart`

- [ ] **Step 1: Add imports for all probes**

```dart
import 'package:telnet_sentinel/probes/ayt_probe.dart';
import 'package:telnet_sentinel/probes/binary_mode_probe.dart';
import 'package:telnet_sentinel/probes/gmcp_probe.dart';
import 'package:telnet_sentinel/probes/malformed_iac_probe.dart';
import 'package:telnet_sentinel/probes/mccp_probe.dart';
import 'package:telnet_sentinel/probes/negotiation_loop_probe.dart';
import 'package:telnet_sentinel/probes/probe_interface.dart';
```

- [ ] **Step 2: Define the list of probes**

Inside `main` or as a helper function:
```dart
final probes = <Probe>[
  HandshakeProbe(),
  AytProbe(),
  BinaryModeProbe(),
  GmcpProbe(),
  MccpProbe(),
  MalformedIacProbe(),
  NegotiationLoopProbe(),
];
```

- [ ] **Step 3: Commit**

```bash
git add bin/telnet_sentinel.dart
git commit -m "cli: import all probes and define probe list"
```

### Task 2: Refactor Connection and Probe Execution Loop

**Files:**
- Modify: `bin/telnet_sentinel.dart`

- [ ] **Step 1: Replace single probe execution with a loop**

Modify the logic after target host/port parsing:

```dart
    final auditResults = <AuditResult>[];

    for (final probe in probes) {
      if (!outputJson && verbose) {
        print('[VERBOSE] Running ${probe.name}...');
      }

      RawSocket? socket;
      try {
        socket = await RawSocket.connect(host, port, timeout: const Duration(seconds: 5));
        final transport = TelnetTransport(socket);
        
        final result = await probe.run(transport);
        auditResults.add(result);
        
        await transport.close();
      } catch (e) {
        auditResults.add(AuditResult(probe.name, AuditStatus.fail, 'Connection/Execution error: $e'));
        socket?.close();
      }
    }
```

- [ ] **Step 2: Verify the loop logic**

Ensure the existing `HandshakeProbe` logic is removed and replaced by this generic loop.

- [ ] **Step 3: Commit**

```bash
git add bin/telnet_sentinel.dart
git commit -m "cli: implement sequential probe execution loop with fresh connections"
```

### Task 3: Final Verification against Live Server

**Files:**
- N/A (Execution and Verification)

- [ ] **Step 1: Run the updated CLI against 127.0.0.1:2323**

Run: `dart bin/telnet_sentinel.dart 127.0.0.1 -p 2323`
Expected: A report showing 7 probes (Handshake, AYT, Binary Mode, GMCP, MCCP, Malformed IAC, Negotiation Loop).

- [ ] **Step 2: Verify JSON output**

Run: `dart bin/telnet_sentinel.dart 127.0.0.1 -p 2323 --json`
Expected: A valid JSON object containing an array of 7 audit results.

- [ ] **Step 3: Verify Verbose output**

Run: `dart bin/telnet_sentinel.dart 127.0.0.1 -p 2323 -v`
Expected: Output includes "[VERBOSE] Running ..." lines for each probe.
