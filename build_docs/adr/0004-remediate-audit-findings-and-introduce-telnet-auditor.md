# ADR-0004: Remediate Adversarial Audit Findings and Introduce TelnetAuditor Facade

## Status

Accepted

## Context

An external adversarial audit report for the `telnet-sentinel` codebase highlighted several critical fragility, stability, resource management, and security issues:
1. **Event Loop Socket Stalling**: The `RawSocket` event handler only read once, failing to drain socket buffers completely, leading to event hang under high-throughput conditions.
2. **Buffer Exhaustion (DoS)**: Lack of size boundaries on `_pendingBytes` in `TelnetTransport` permitted Out of Memory (OOM) crashes via unclosed or massive subnegotiations.
3. **Unsafe GMCP Decoding**: The GMCP parser crashed when decoding malformed UTF-8 sequences.
4. **Native Zlib Resource Leaks**: Allocated chunked conversion sinks in MCCP2 decompression were never disposed of.
5. **Incomplete RFC 1143 Q-Method**: The state manager lacked intermediate queuing states (`wantYesOpposite`, `wantNoOpposite`), leading to potential loop vulnerabilities during reordered packet handshakes.
6. **Probe Completer Safety**: Stream listeners inside handshake and binary mode probes attempted to double-complete a `Completer`, throwing an unhandled `StateError`.
7. **GMCP Double IAC (Escaped 255) Handling**: Escaped `255 255` sequences inside subnegotiation payload streams were not unescaped, causing GMCP decoding failures.
8. **Lifecycle Boilerplate Leakage**: Library consumers were forced to manage individual socket connections and probe execution loops, polluting the CLI entry point.

## Decision

To remediate these issues, we adopted a series of systematic fixes across the core architecture:
1. **Robust Socket Draining**: Wrapped `RawSocket` reading in a `while (avail > 0)` loop inside `_onSocketEvent` (safeguarded by try-catch fallback handling on `available()`).
2. **Memory Buffer Ceiling**: Enforced a strict `64KB` ceiling on raw transport buffers, throwing a custom `TelnetProtocolException` if exceeded.
3. **Safe UTF-8 Decoding**: Wrapped the GMCP payload decoder in a try-catch block and enabled `allowMalformed: true`.
4. **Zlib Sink Resource Clean-up**: Retained a reference to `_decompressorSink` and closed it cleanly within `TelnetTransport.close()`.
5. **Full RFC 1143 Q-Method State Machine**: Redefined `OptionState` to incorporate the 6 full Q-method states and completely implemented the official state transition table.
6. **Guard Completers**: Added `if (completer.isCompleted) return;` at the top of probe event subscriptions.
7. **IAC Unescaping**: Transformed escaped `255 255` sequences back to a single `255` inside the payload chunk of subnegotiations at the transport layer.
8. **Relocation & Clean-up**: Moved the root-level scratch script to `tool/manual_telnet_verification/check_zlib.dart` and shifted `yaml` to `dev_dependencies`.
9. **Unified Auditor Facade**: Introduced the `TelnetAuditor` class inside `lib/telnet_auditor.dart` which exposes a single high-level `runSuite()` method to handle the socket connection, execute probes sequentially, and expose real-time sniffer hooks. Refactored the CLI entry point `bin/telnet_sentinel.dart` to delegate to this auditor.

## Alternatives Considered

An alternative to RFC 1143 Q-method would be simple negotiation rate-limiting. However, this is non-standard and highly fragile under network jitter, whereas a true FSM queue-bit implementation guarantees absolute loop immunity natively.

Another alternative to `TelnetAuditor` would be maintaining separate utility functions for socket initialization. However, encapsulation under a single facade provides the cleanest, most readable, and standard API for library clients.

## Consequences

- **Stability**: Absolute protection against infinite negotiation loops, socket event hangs, and unhandled parser crashes.
- **Safety**: Out-of-memory safeguards enforce strict ceilings on input data lengths.
- **Maintainability**: Reduced CLI boilerplate from >200 lines of manual socket orchestration to a simple 6-line `TelnetAuditor` execution call.
- **Resource Cleanliness**: Native heap Zlib references are explicitly disposed of on teardown.
