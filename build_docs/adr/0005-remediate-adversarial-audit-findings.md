# ADR-0005: Remediate Pre-Publication Adversarial Audit Findings

## Status

Accepted

## Context

A second pre-publication adversarial audit of the `telnet-sentinel` codebase uncovered several critical bugs, resource leaks, and structural issues:
1. **False-Positive Probing**: `AytProbe` and `MalformedIacProbe` listened to incoming socket events and immediately passed upon receiving any `data` event. This caused false-positives because standard servers immediately send connection banners or welcome prompts, triggering a complete `PASS` before commands were processed or checked.
2. **Execution Hangs on Server Disconnects**: Several probes lacked an `onDone` callback on their stream subscriptions. Abrupt connection closes by target servers left the internal `Completer` open, causing the auditor to hang until passive timeouts (5-10s) expired.
3. **Silent GMCP JSON Parser Failures**: trailing null characters (`\u0000`) inside GMCP payloads (common in MUD servers) caused `jsonDecode` to throw exceptions, which were silently swallowed, losing critical out-of-band data.
4. **Memory Leak and Descriptor Exhaustion on Teardown**: `TelnetTransport.close()` failed to close the raw socket or controller stream if `_socket.shutdown()` threw a `SocketException` (e.g. if the socket was already reset by peer).
5. **Broken Package Structure**: The package lacked a standardized programmatic library entry point (`lib/telnet_sentinel.dart`) and exposed internal components directly under `lib/`, violating Dart package design principles.
6. **Infinite Retries on Dead Hosts**: The auditor established fresh TCP connections for each probe in a loop, resulting in a 35-second hang when auditing unreachable hosts.
7. **Facade Separation of Concerns Violation**: `TelnetAuditor` hardcoded ANSI escape sequences and direct console `print()` calls inside its core, violating headless library principles.
8. **Under-Expressive Result Models**: The `AuditResult` model was missing timing (latency) and raw bytes historical records.
9. **Option Negotiation Loops (DoS)**: While RFC 1143 protects against locally-initiated FSM loops, a buggy or malicious remote peer could repeatedly send alternating negotiation states to trigger client-side CPU exhaustion.
10. **Stale Documentation Paths**: Root-level `AGENTS.md` instructions directed automated assistants to read documentation from compiled `/docs/` paths instead of the source `/build_docs/` paths.

## Decision

To systematically remediate all 10 findings, we implemented the following technical decisions:
1. **Welcome-Banner Draining Phase**: Retooled `AytProbe` to introduce a 200ms initial connection window that ignores/drains welcome banner data, only setting `aytSent = true` and completing on data received after sending the command.
2. **Responsive Probe Teardown**: Added `onDone` callbacks to the stream subscriptions in `HandshakeProbe`, `AytProbe`, `BinaryModeProbe`, `GmcpProbe`, and `MccpProbe` to immediately fail with a "Connection abruptly closed by server" status rather than hanging.
3. **Null-Termination Cleaning**: Updated `GmcpParser.parse` to strip trailing `0x00` bytes from payloads and clean any `\u0000` null characters from JSON strings before decoding.
4. **Resilient Socket Teardown**: Wrapped `_socket.shutdown()` inside a try-catch block, and placed socket closing and controller stream teardown inside a `finally` block to guarantee native file descriptors are always released.
5. **Standardized Package Surface**: Created `lib/telnet_sentinel.dart` to export the public API facade, and moved all internal implementation directories into a private `lib/src/` folder.
6. **Pre-Flight Reachability Sanity Check**: Implemented a rapid connection test at the start of `TelnetAuditor.runSuite`. If host reachability fails, skip all subsequent probes and abort immediately.
7. **Pure Headless Library Core**: Stripped all direct `print` statements and ANSI coloring out of `TelnetAuditor`. Shifted Sniffer output rendering completely to the CLI caller via the `onSnifferEvent` callback.
8. **Enriched Audit Diagnostics**: Added `latency` and `rawBytesExchanged` fields to `AuditResult` and `TelnetTransport`, serializing them into JSON.
9. **FSM Reply Rate-Limiting**: Introduced option-specific rate-limiting inside `NegotiationStateManager` to halt outbound option replies if a single option undergoes 5 or more transitions within 1 second.
10. **Path Corrections**: Updated root `AGENTS.md` and handbook references to point to `build_docs/`.

## Alternatives Considered

- **Single-Socket Shared Session Auditing**: Rather than opening a new socket for each probe, running all probes over a single persistent session. While highly efficient, this is deferred to a future major version release because some probes intentionally send invalid protocol commands or trigger loop tests which would contaminate subsequent tests in a shared session. 

## Consequences

- **Stability**: Elimination of socket resource leaks, dangling file descriptors, and parser crashes.
- **Diagnostics**: High-value latencies and raw byte history captured natively.
- **Clean API**: Library consumers can import `package:telnet_sentinel/telnet_sentinel.dart` cleanly.
- **Resilience**: Protection against peer FSM negotiation loop attacks.
