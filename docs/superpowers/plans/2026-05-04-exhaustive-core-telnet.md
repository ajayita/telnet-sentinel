# Core Telnet Implementation Plan (RFC 854 Exhaustion)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Achieve exhaustive coverage of the core Telnet protocol (RFC 854) and common core extensions (RFC 856, 857).

**Architecture:** Extend the existing `NegotiationStateManager` and `TelnetTransport` to handle 2-byte and 3-byte core commands, and implement specialized probes for each feature.

**Tech Stack:** Dart, `dart:io`.

---

### Task 5.1: Core Command Handling (AYT, AO, IP, BRK, EL, EC, NOP)

**Files:**
- Modify: `lib/transport/telnet_transport.dart`
- Modify: `lib/state/negotiation_state_manager.dart`
- Create: `lib/probes/ayt_probe.dart`

- [ ] **Step 1: Update TelnetTransport to emit 2-byte commands cleanly**
Ensure commands like AYT (246), AO (245), etc., are emitted as `TelnetEvent`s.

- [ ] **Step 2: Implement AYT response in NegotiationStateManager**
When receiving `AYT`, send a [NOP] or a specific string response as defined by the user (defaulting to a safe NOP).

- [ ] **Step 3: Implement AytProbe**
Sends `AYT` and waits for any response from the server.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: implement AYT command handling and probe"`

### Task 5.2: Advanced Sub-negotiation (SB/SE) & Binary Mode

**Files:**
- Modify: `lib/transport/telnet_transport.dart`
- Modify: `lib/state/negotiation_state_manager.dart`
- Create: `lib/probes/binary_mode_probe.dart`

- [ ] **Step 1: Enhance SB parsing in TelnetTransport**
Ensure SB data correctly handles escaped IACs (`0xFF 0xFF`) within the sub-negotiation block.

- [ ] **Step 2: Implement Binary Mode (RFC 856) state in NegotiationStateManager**
Track binary mode state to ensure we don't accidentally decode 8-bit data as UTF-8.

- [ ] **Step 3: Implement BinaryModeProbe**
Request `DO BINARY` and verify the server's acknowledgment.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: implement advanced SB parsing and binary mode probe"`

### Task 5.3: Stress & Adversarial Probes

**Files:**
- Create: `lib/probes/malformed_iac_probe.dart`
- Create: `lib/probes/negotiation_loop_probe.dart`

- [ ] **Step 1: Implement MalformedIacProbe**
Send invalid Telnet sequences (e.g., `IAC` followed by an undefined command, or an unclosed `SB`) and verify the connection remains stable.

- [ ] **Step 2: Implement NegotiationLoopProbe**
Attempt to trigger a negotiation loop by repeatedly sending a toggle request and verify the `NegotiationStateManager` prevents the loop.

- [ ] **Step 3: Commit**
`git add . && git commit -m "feat: add adversarial probes for protocol stability"`
