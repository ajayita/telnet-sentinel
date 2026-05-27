# Adversarial Audit Report: telnet-sentinel

**Author**: Hostile Senior Reviewer  
**Target**: `telnet-sentinel` Codebase  
**Status**: Pre-Publication Review  
**Date**: May 26, 2026  

---

## 1. Executive Summary

The `telnet-sentinel` codebase is a facade of stability built on highly fragile foundations. While the project boasts clean code formatting, zero linter warnings, and a superficially rigorous YAML-based and scenario-based test suite, the underlying implementation is plagued by critical testing illusions, resource leaks, and severe protocol corner-case bugs. Most egregiously, the **AYT** and **Malformed IAC** probes suffer from massive false-positive vulnerabilities where they blindly pass upon receiving *any* pre-existing server connection banner, rendering their adversarial claims completely meaningless. Furthermore, low-level transport errors and abrupt server disconnects trigger socket/controller resource leaks and persistent execution hangs. This package is absolutely not production-ready; it requires significant architectural refinement and severe bug remediation before public release.

---

## 2. Findings by Severity

### CRITICAL

#### 1. False-Positive Validation in `AytProbe` and `MalformedIacProbe`
*   **File + Line**: [ayt_probe.dart:33-41](file:///home/ajayiot/Projects/telnet-sentinel/lib/probes/ayt_probe.dart#L33-L41), [malformed_iac_probe.dart:15-27](file:///home/ajayiot/Projects/telnet-sentinel/lib/probes/malformed_iac_probe.dart#L15-L27)
*   **Description**: Both probes listen to the incoming `TelnetEvent` stream and immediately complete with a `PASS` status if *any* `data` event is received. Since almost all standard Telnet and MUD servers automatically transmit a welcome banner or login prompt immediately upon TCP socket establishment, these welcome bytes are processed and emitted as a `data` event as soon as the listener attaches. The probes intercept this pre-existing welcome data and immediately complete as `PASS` *before* the probe's commands (like AYT or malformed sequences) are even fully sent to the socket.
*   **Impact**: The test is a complete illusion. A target server could ignore AYT, crash on malformed sequences, or hang entirely, but the probe will still report a successful `PASS` solely because the server sent its initial connection banner. The claim of "Adversarial Probing" is mathematically hollow in its current state.
*   **Fix**: Do not complete on arbitrary, unsolicited data. For `AytProbe`, only complete on a `data` event if it was received *after* the AYT command was flushed, and ensure it represents a valid response (or ignore the initial welcome buffer). For `MalformedIacProbe`, only begin listening for the AYT response *after* the malformed sequences have been fully written and a small delay has elapsed to check for crashes.

---

### HIGH

#### 2. Probe Execution Hangs on Abrupt Connection Close
*   **File + Line**: [handshake_probe.dart:21-63](file:///home/ajayiot/Projects/telnet-sentinel/lib/probes/handshake_probe.dart#L21-L63), [ayt_probe.dart:21-55](file:///home/ajayiot/Projects/telnet-sentinel/lib/probes/ayt_probe.dart#L21-L55), [binary_mode_probe.dart:20-63](file:///home/ajayiot/Projects/telnet-sentinel/lib/probes/binary_mode_probe.dart#L20-L63), [gmcp_probe.dart:25-92](file:///home/ajayiot/Projects/telnet-sentinel/lib/probes/gmcp_probe.dart#L25-L92), [mccp_probe.dart:25-87](file:///home/ajayiot/Projects/telnet-sentinel/lib/probes/mccp_probe.dart#L25-L87)
*   **Description**: These 5 core probes listen to the `transport.events` stream but do *not* register an `onDone` callback on the subscription. If the target server abruptly closes the connection, the socket stream terminates. Because `onDone` is ignored, the internal `Completer` is left open, and the probe hangs until its internal timeout (5 or 10 seconds) expires.
*   **Impact**: If a server closes the connection midway or crashes under load, the remaining sequential probes will each hang for 5 seconds. The tool will wait up to 25 seconds unnecessarily, and falsely report "Timeout waiting for response" instead of "Connection terminated by remote peer."
*   **Fix**: Implement `onDone` in the stream subscriptions of all probes, and immediately complete the `Completer` with a `fail` status indicating "Connection abruptly closed by server."

#### 3. Silent GMCP Parser Failures on Null-Terminated Payloads
*   **File + Line**: [gmcp_parser.dart:24-30](file:///home/ajayiot/Projects/telnet-sentinel/lib/transport/gmcp_parser.dart#L24-L30), [gmcp_parser.dart:41-53](file:///home/ajayiot/Projects/telnet-sentinel/lib/transport/gmcp_parser.dart#L41-L53)
*   **Description**: Many standard Telnet MUD servers null-terminate the JSON strings inside GMCP subnegotiations. In `GmcpParser.parse`, the bytes are converted to a string via `utf8.decode(...)` and trimmed. However, `String.trim()` in Dart only removes whitespace characters (`\s`), leaving the trailing null character (`\u0000`) intact. Passing a string with a trailing null character to `jsonDecode` throws a `FormatException`, which is caught by the try-catch block and silently swallowed, returning a `GmcpEvent` with an empty data map `{}`.
*   **Impact**: Completely silent loss of GMCP data. The probe reports a successful parsing event but discards the entire payload contents, leading to massive debugging confusion.
*   **Fix**: Explicitly strip trailing null bytes (`0x00`) from the `payloadBytes` array before decoding, or remove `\u0000` from the decoded string before invoking `jsonDecode`.

#### 4. Memory Leak and File Descriptor Exhaustion on Socket Teardown Failures
*   **File + Line**: [telnet_transport.dart:205-212](file:///home/ajayiot/Projects/telnet-sentinel/lib/transport/telnet_transport.dart#L205-L212)
*   **Description**: In `TelnetTransport.close()`, the method calls `_socket.shutdown(SocketDirection.both)`. If the socket has already been closed by the remote host or reset by peer, `shutdown` throws an unhandled `SocketException`. Since the method lacks a try-catch or a `finally` block, the exception aborts execution, completely skipping `_socket.close()` and the `_onDone()` call that closes the internal stream controller.
*   **Impact**: Severe resource leaks. Stream controllers remain open in memory, and native file descriptors (sockets) are left dangling in the OS, guaranteeing eventual file descriptor exhaustion during continuous automated audits.
*   **Fix**: Wrap `_socket.shutdown` in a try-catch block, and wrap the socket close and stream controller teardown in a `finally` block to ensure they are always executed.

#### 5. Broken Package Structure (Missing Entry Point)
*   **File + Line**: [pubspec.yaml](file:///home/ajayiot/Projects/telnet-sentinel/pubspec.yaml), `lib/` directory structure
*   **Description**: The package lacks the mandatory package entry point file `lib/telnet_sentinel.dart`.
*   **Impact**: Developers attempting to use this library programmatically are blocked from using standard import syntax: `import 'package:telnet_sentinel/telnet_sentinel.dart';`. They are forced to import internal files directly (e.g. `import 'package:telnet_sentinel/telnet_auditor.dart';`), violating Dart library design guidelines and resulting in massive pub.dev scoring penalties.
*   **Fix**: Create `lib/telnet_sentinel.dart` and export all public classes (`TelnetAuditor`, `AuditReport`, etc.), and move internal implementation files to a dedicated `lib/src/` subdirectory.

---

### MEDIUM

#### 6. Infinite Retries on Down Hosts (Hang Vulnerability)
*   **File + Line**: [telnet_auditor.dart:55-99](file:///home/ajayiot/Projects/telnet-sentinel/lib/telnet_auditor.dart#L55-L99)
*   **Description**: The sequential nature of `TelnetAuditor.runSuite` means it establishes a brand new TCP connection for each probe in a loop. If a target server is down, firewalled, or unreachable, `RawSocket.connect` hangs for the duration of the timeout (5 seconds). Because the auditor loops through 7 probes unconditionally, it will attempt to connect 7 separate times, hanging for up to 35 seconds just to report that the host is dead.
*   **Impact**: Terrible user experience and complete lack of pre-flight connection checks.
*   **Fix**: Implement a single connection sanity check. If the first probe fails with a connection error (such as `SocketException`), cancel all subsequent probes and abort the audit immediately.

#### 7. Separation of Concerns Violation (Direct Console Printing in Library Facade)
*   **File + Line**: [telnet_auditor.dart:104-113](file:///home/ajayiot/Projects/telnet-sentinel/lib/telnet_auditor.dart#L104-L113)
*   **Description**: The library facade `TelnetAuditor` hardcodes ANSI colored output (`print(...)`) directly inside `_defaultSnifferPrint` when the `sniffer` flag is set to true.
*   **Impact**: Coupled library logic. If this library is integrated into a GUI application, automated CI service, or logging server, enabling `sniffer: true` will write un-redactable, raw console escape sequences to the host system's standard output, violating headless design principles.
*   **Fix**: Completely remove `print` statements from `TelnetAuditor`. The CLI caller should register a handler via the `onSnifferEvent` callback, formatting and printing the events purely on the application side.

#### 8. Insufficient Audit Result Expressiveness (Missing Timing and Raw Bytes)
*   **File + Line**: [audit_result.dart](file:///home/ajayiot/Projects/telnet-sentinel/lib/models/audit_result.dart)
*   **Description**: The `AuditResult` model lacks fields representing the latency (duration) of the probe or the raw bytes exchanged during a failure.
*   **Impact**: Extremely low diagnostics value. A protocol auditor should help developers identify *why* a sequence failed or *how slow* a handshake was. Currently, developers cannot inspect raw byte exchanges without manually tailing terminal output in Sniffer Mode.
*   **Fix**: Add `Duration latency` and `List<int>? rawBytesExchanged` to the `AuditResult` structure, and serialize them into the JSON report.

#### 9. Vulnerability to Peer-Initiated Negotiation Loops (FSM Denial of Service)
*   **File + Line**: [negotiation_state_manager.dart](file:///home/ajayiot/Projects/telnet-sentinel/lib/state/negotiation_state_manager.dart)
*   **Description**: While the state manager fully implements the RFC 1143 Q-method state transitions to prevent *locally* initiated negotiation loops, it lacks protection against loops initiated by a buggy or malicious remote host. If a remote host repeatedly sends conflicting commands (`DO ECHO` -> `DONT ECHO` -> `DO ECHO` ...), the manager will blindly reply to every single command.
*   **Impact**: The client is highly vulnerable to CPU exhaustion (Denial of Service) if targeted by a malicious Telnet server.
*   **Fix**: Implement an option-specific counter inside `NegotiationStateManager` that tracks negotiation frequency and halts option replies if consecutive state changes exceed a safety threshold (e.g. 5 changes within 1 second).

---

### NITPICK

#### 10. Stale and Misleading Documentation Paths in `AGENTS.md`
*   **File + Line**: [AGENTS.md:7-9](file:///home/ajayiot/Projects/telnet-sentinel/AGENTS.md#L7-L9)
*   **Description**: The root-level AI agent instructions document directs agents to read authoritative documentation under `docs/handbook/`, `docs/adr/`, and `docs/working-notes/`. However, these markdown source folders actually reside under `build_docs/`, and `docs/` is the compiled output folder containing static HTML.
*   **Impact**: AI tools will throw file system errors or waste context tokens attempting to read markdown files from compiled paths.
*   **Fix**: Correct the paths in `AGENTS.md` to reference `build_docs/...`.

---

## 3. Feature Claim Verification Table

| README Feature Claim | Implementation Status | Verification Details / Flaws |
| :--- | :--- | :--- |
| **Active Protocol Auditing** | **Partially Implemented** | Exists, but relies on 7 separate sequential socket connections. `AytProbe` has a critical false-positive flaw. |
| **Adversarial Probing** | **Partially Implemented** | Malformed sequence generation is written, but `MalformedIacProbe` has a critical false-positive flaw where it passes on initial banners. |
| **MUD Extensions (MCCP2)** | **Verified** | Standard Zlib stream decompression works. |
| **MUD Extensions (GMCP)** | **Partially Implemented** | GMCP parsing is present, but fails completely on standard null-terminated JSON payloads. |
| **Traffic Visualizer (sniffer)** | **Verified** | Real-time events are visible, but hardcoded inside the library facade. |
| **Machine-Readable JSON Reports**| **Verified** | Valid JSON reports are emitted cleanly. |

---

## 4. Test Coverage Assessment

### What Is Tested
*   Low-level `TelnetTransport` parsing (escaped characters, subnegotiation chunks).
*   Low-level `NegotiationStateManager` FSM Q-method state transitions.
*   Basic success/failure paths for each probe under controlled mock loopback servers.
*   JSON serialization and deserialization.

### What Is NOT Tested
*   **False-Positive Immunity**: The tests do *not* verify whether the probes correctly ignore initial welcome banners. As a result, the critical false-positive loop vulnerability in `AytProbe` and `MalformedIacProbe` went completely undetected.
*   **Teardown Socket Exceptions**: The tests do *not* assert socket shutdown failures, allowing the high-severity resource leak in `TelnetTransport.close()` to go unnoticed.
*   **Null-Terminated GMCP Payloads**: No test cases exercise null-terminated JSON strings, resulting in the GMCP parser's trailing null bug remaining uncaught.
*   **Unreachable Hosts**: No tests verify the behavior of `TelnetAuditor` when the target host is entirely down or unreachable.

---

## 5. Architecture Verdict

The overall architectural design of `telnet-sentinel` is **unstable for production use**. 

### Critical Flaws
1.  **Redundant Socket Lifecycle**: Establishing a fresh TCP connection for every sequential probe is extremely inefficient, slows execution by up to 7x the base latency, and is highly prone to triggering firewall blocks or port exhaustion.
2.  **Lack of State Retention**: Running sequential probes on distinct TCP sockets means there is no progression of state. If a server requires authentication or negotiates a base state during the first probe, that state is entirely lost when the second probe reconnects.
3.  **Fragile Low-Level API**: Low-level stream handling is highly susceptible to unhandled exception crashes during disconnects. The library relies on passive timeouts rather than active close handling in its stream subscriptions.

### Proposed Production-Quality Design
*   **Single-Connection Session Lifespans**: Probes should operate within a single, persistent session managed by `TelnetTransport`. The `TelnetAuditor` should open the socket *once*, run all active probes sequentially over that single transport session (or in parallel if they do not conflict), and close the transport exactly once.
*   **Pure Headless Library Core**: Remove all console rendering (`print()`) and hardcoded ANSI formatting from `lib/`. The library must be purely headless and expose only events/callbacks.
*   **Strict Package Boundaries**: Create a clean exported library surface in `lib/telnet_sentinel.dart` and isolate all internal implementations to `lib/src/` to prevent caller import pollution.

---

## 6. Prioritized Fix List

If you have one week to make this codebase ready for release, implement the following top 10 fixes in this exact order:

1.  **Fix `AytProbe` False-Positive**: Update `AytProbe.run` to explicitly ignore data events received before the AYT command is sent, or ignore the initial welcome buffer, and only complete when a genuine response is received.
2.  **Fix `MalformedIacProbe` False-Positive**: Re-architect the probe to write all malformed sequences, wait briefly, and only attach the stream listener *after* the sequences have been fully sent and the checking AYT is issued.
3.  **Remediate `TelnetTransport.close()` Resource Leak**: Wrap the `_socket.shutdown` call in a try-catch block to ensure that socket closing and controller stream closure are never bypassed.
4.  **Fix GMCP Parser Null-Termination Bug**: Update `GmcpParser.parse` to strip trailing null bytes (`0x00`) from the payload before decoding to prevent `jsonDecode` failure.
5.  **Add `onDone` Handlers to Probes**: Register the `onDone` callback on the stream subscriptions inside `HandshakeProbe`, `AytProbe`, `BinaryModeProbe`, `GmcpProbe`, and `MccpProbe` to immediately fail with a "Connection terminated by server" message instead of hanging.
6.  **Create Package Entry Point**: Create `lib/telnet_sentinel.dart` to export the public facade, and move all internal files into a dedicated `lib/src/` folder.
7.  **Implement CLI Pre-Flight Connection Check**: Add logic in `TelnetAuditor` to quickly check host reachability once, and fail the entire suite immediately if unreachable, preventing the 35-second retry loop.
8.  **Remove Direct Printing in Facade**: Strip all `print` and ANSI colored strings from `TelnetAuditor._defaultSnifferPrint`, shifting Sniffer rendering responsibility entirely to `bin/telnet_sentinel.dart` using the `onSnifferEvent` callback.
9.  **Enrich `AuditResult` Model**: Add `Duration latency` and `List<int>? rawBytesExchanged` to the audit models, and update the CLI's JSON report writer to output them.
10. **Correct `AGENTS.md` Documentation Paths**: Change the stale documentation paths in the AI agent instructions from `docs/` to `build_docs/`.
