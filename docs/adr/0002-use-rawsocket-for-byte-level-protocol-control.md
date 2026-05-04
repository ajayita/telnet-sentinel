# ADR-0002: Use RawSocket for Byte-Level Protocol Control

## Status

Accepted

## Context

Telnet is a byte-oriented protocol that uses the `IAC` (Interpret As Command, `0xFF`) byte as a control character. Standard high-level socket implementations (like Dart's `Socket`) often perform automatic buffering and UTF-8 decoding. This is a liability for an auditing tool because:
1.  **Byte Mangling**: UTF-8 decoders may mangle binary control sequences if they are misinterpreted as text.
2.  **Timing & Buffering**: High-level sockets may flush buffers in a way that obscures the boundary of sub-negotiations.
3.  **State Visibility**: We need to intercept and react to every individual byte to maintain an accurate protocol state machine.

## Decision

We will use **`RawSocket`** instead of the high-level `Socket` class.

`RawSocket` provides low-level, event-driven access to the underlying data stream. This allows us to:
- Handle `RawSocketEvent.read` events to process bytes exactly as they arrive.
- Perform manual byte-by-byte parsing of `IAC` sequences.
- Avoid any automatic string decoding until the byte stream has been stripped of protocol control sequences.

## Alternatives Considered

- **Standard `Socket`**: Rejected due to automatic decoding and lack of granular control over the raw byte stream.
- **`dart:io` with custom Transformers**: Considered, but `RawSocket` provides a cleaner, more direct interface for low-level protocol auditing.

## Consequences

- **Complexity**: We must manually handle byte-to-string conversion for user-visible text.
- **Reliability**: We gain full control over the Telnet state machine, enabling robust auditing of malformed or adversarial protocol sequences.
- **Portability**: Low-level socket behavior is consistent across platforms, ensuring our "synthetic auditor" remains predictable.
