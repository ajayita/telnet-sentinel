# UI & Reporting Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the CLI with machine-readable output and a live traffic visualizer.

**Architecture:** Use `jsonEncode` for the `--json` flag. For the traffic visualizer, implement a "Sniffer" mode that prints Telnet events in real-time.

---

### Task 7.1: JSON Output

**Files:**
- Modify: `bin/telnet_sentinel.dart`
- Modify: `lib/models/audit_result.dart`
- Modify: `lib/models/audit_report.dart`
- Test: `test/models/json_serialization_test.dart`

- [ ] **Step 1: Add JSON serialization to models**
Implement `toJson()` methods for `AuditResult` and `AuditReport`.

- [ ] **Step 2: Add `--json` flag to CLI**
Update the `ArgParser` in `bin/telnet_sentinel.dart`.

- [ ] **Step 3: Implement JSON reporting logic**
If the flag is present, print the JSON-encoded report instead of the human-readable one.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: add JSON output support to CLI"`

### Task 7.2: Sniffer Mode (Traffic Visualizer)

**Files:**
- Modify: `bin/telnet_sentinel.dart`

- [ ] **Step 1: Add `--sniffer` flag to CLI**
Allows users to see raw Telnet negotiation events in real-time.

- [ ] **Step 2: Implement Sniffer logic**
In sniffer mode, the CLI should print every `TelnetEvent` as it arrives, with colorized output for IAC commands.

- [ ] **Step 3: Commit**
`git add . && git commit -m "feat: add sniffer mode for real-time traffic visualization"`
