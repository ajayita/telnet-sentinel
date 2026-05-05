# MUD Extensions Implementation Plan - MCCP (Zlib Compression)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement support for MCCP2 (MUD Client Compression Protocol) to allow auditing of compressed Telnet streams.

**Architecture:** MCCP2 works by negotiating option 86. Once the server sends `IAC SB MCCP2 IAC SE`, all subsequent bytes are Zlib-compressed. We need a `DecompressingTransport` wrapper or an internal state change in `TelnetTransport` to handle this transition.

**Tech Stack:** Dart, `dart:io` (ZLibDecoder).

---

### Task 6.1: Zlib Integration & Decompression Logic

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/transport/telnet_transport.dart`
- Test: `test/transport/mccp_transport_test.dart`

- [ ] **Step 1: Verify Zlib availability**
Dart's `dart:io` provides `ZLibDecoder`. No external dependency is strictly needed if we can handle the stream correctly, but we'll check if a more flexible package like `archive` is required for raw zlib streams.

- [ ] **Step 2: Implement MCCP Decompression Layer**
Add a mechanism to `TelnetTransport` to switch from raw byte reading to a decompressing stream when `IAC SB MCCP2 IAC SE` is detected.

- [ ] **Step 3: Write tests for compressed streams**
Verify that the transport can handle a mix of uncompressed negotiation followed by a compressed data stream.

- [ ] **Step 4: Commit**
`git add . && git commit -m "feat: implement MCCP2 decompression in TelnetTransport"`

### Task 6.2: MCCP Probe

**Files:**
- Create: `lib/probes/mccp_probe.dart`
- Test: `test/probes/mccp_probe_test.dart`

- [ ] **Step 1: Implement MccpProbe**
Request `DO MCCP2` (option 86). Wait for `WILL MCCP2`. Then wait for the sub-negotiation start. Once compression begins, verify that the decompressed stream contains valid data (e.g., a "Welcome" message).

- [ ] **Step 2: Write tests for MccpProbe**
Mock a server that negotiates MCCP2 and sends a compressed payload.

- [ ] **Step 3: Commit**
`git add . && git commit -m "feat: add MCCP2 auditing probe"`
