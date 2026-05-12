# Telnet Sentinel Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the core "Active Prober" framework, including byte-level transport, state management, and a plugin-based probing system.

**Architecture:** A library-first approach using `RawSocket` for byte-level control. A central `NegotiationStateManager` handles the Telnet state machine, while a `ProbeInterface` allows for RFC-specific auditing modules.

**Tech Stack:** Dart, `dart:io` (RawSocket), `args`.

---

### Task 1: Foundation - Transport & Basic IAC Models

**Files:**
- Create: `lib/transport/telnet_transport.dart`
- Create: `lib/models/telnet_event.dart`
- Test: `test/transport/telnet_transport_test.dart`

- [ ] **Step 1: Define Telnet Event models**
```dart
enum TelnetEventType { iac, data }
class TelnetEvent {
  final TelnetEventType type;
  final List<int> bytes;
  TelnetEvent(this.type, this.bytes);
}
```

- [ ] **Step 2: Create TelnetTransport using RawSocket**
Implement a wrapper around `RawSocket` that emits `TelnetEvent`s.

- [ ] **Step 3: Write tests for byte-stream separation**
Verify that `0xFF` (IAC) sequences are correctly identified and separated from literal data.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: add basic transport and event models"`

### Task 2: Negotiation State Manager

**Files:**
- Create: `lib/state/negotiation_state_manager.dart`
- Test: `test/state/negotiation_state_manager_test.dart`

- [ ] **Step 1: Implement the WILL/WONT/DO/DONT state machine**
Create a class to track local and remote option states.

- [ ] **Step 2: Handle loop prevention**
Ensure that responding to a negotiation doesn't trigger an infinite cycle.

- [ ] **Step 3: Write unit tests for state transitions**
Verify that receiving `DO ECHO` updates the state correctly and generates the appropriate `WILL/WONT` response.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: implement negotiation state manager"`

### Task 3: Probe Interface & Handshake Audit

**Files:**
- Create: `lib/probes/probe_interface.dart`
- Create: `lib/probes/handshake_probe.dart`
- Test: `test/probes/handshake_probe_test.dart`

- [ ] **Step 1: Define ProbeInterface**
```dart
abstract class Probe {
  String get name;
  Future<AuditResult> run(TelnetTransport transport);
}
```

- [ ] **Step 2: Implement HandshakeProbe**
A basic probe that verifies if the server responds to a standard terminal-type negotiation.

- [ ] **Step 3: Write tests for HandshakeProbe**
Verify that the probe correctly identifies a successful negotiation vs. a timeout/rejection.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: add probe interface and initial handshake probe"`

### Task 4: CLI Integration & Reporting

**Files:**
- Modify: `bin/telnet_sentinel.dart`
- Create: `lib/models/audit_report.dart`

- [ ] **Step 1: Implement AuditReport model**
A class to aggregate results from multiple probes.

- [ ] **Step 2: Update CLI to use TelnetTransport and Probes**
Connect to a target host and run the enabled probes.

- [ ] **Step 3: Implement human-readable console output**
Format the `AuditReport` for the terminal.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: integrate probes into CLI and add reporting"`
