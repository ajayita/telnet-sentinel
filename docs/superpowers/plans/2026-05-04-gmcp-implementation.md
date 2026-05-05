# MUD Extensions Implementation Plan - GMCP (Out-of-band Data)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement support for GMCP (Generic MUD Communication Protocol) to audit out-of-band data integrity.

**Architecture:** GMCP uses Telnet Option 201. Data is sent as `IAC SB 201 Package.Message {JSON} IAC SE`. We need a parser to extract the package/message and the JSON payload.

**Tech Stack:** Dart, `dart:convert` (jsonDecode).

---

### Task 6.2: GMCP Parser & Model

**Files:**
- Create: `lib/models/gmcp_event.dart`
- Create: `lib/transport/gmcp_parser.dart`
- Test: `test/transport/gmcp_parser_test.dart`

- [ ] **Step 1: Define GmcpEvent model**
```dart
class GmcpEvent {
  final String package;
  final String message;
  final Map<String, dynamic> data;
  GmcpEvent(this.package, this.message, this.data);
}
```

- [ ] **Step 2: Implement GmcpParser**
A utility class or method to parse raw SB 201 bytes into a `GmcpEvent`.

- [ ] **Step 3: Write tests for GMCP parsing**
Verify that `Core.Welcome {"version": "1.0"}` is correctly parsed.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: add GMCP event model and parser"`

### Task 6.3: GMCP Probe

**Files:**
- Create: `lib/probes/gmcp_probe.dart`
- Test: `test/probes/gmcp_probe_test.dart`

- [ ] **Step 1: Implement GmcpProbe**
Negotiate `DO GMCP` (option 201). Once the server sends a GMCP message, verify that it is valid JSON and correctly structured.

- [ ] **Step 2: Write tests for GmcpProbe**
Mock a server that sends a valid GMCP payload after negotiation.

- [ ] **Step 3: Commit**
`git add . && git commit -m "feat: add GMCP auditing probe"`
