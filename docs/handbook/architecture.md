# Architecture

`telnet-sentinel` is a diagnostic and auditing framework designed to verify the integrity and compliance of Telnet server implementations.

## The "Active Prober" Model

The application functions by simulating a wide variety of user environments and "stressful" scenarios. Instead of a passive connection, it uses a series of **Probes**:

1.  **The Handshake Audit**: It negotiates features like window sizing, terminal type, and color support to ensure the server reacts correctly to different devices.
2.  **The Stress Test**: It sends unexpected or slightly malformed commands to see if the server handles errors gracefully or crashes.
3.  **The Extension Validator**: Specifically for MUDs, it verifies advanced features like data compression (MCCP) and out-of-band data (GMCP/MSDP) which power modern game interfaces.

## Why This Matters

In network communication, "invisible" bugs are the most dangerous. A server might seem fine until a specific combination of terminal settings causes it to lag, leak data, or disconnect users. Telnet Sentinel turns these invisible risks into a **detailed compliance report**, allowing developers to fix protocol flaws before they impact real-world users. By providing a "Scorecard" for protocol health, it ensures that even the oldest technologies can run with modern-day reliability.

## System Overview

The application is structured as a **Library-First** implementation, ensuring the core auditing logic is decoupled from its interface (CLI or GUI).

### Core Components

1.  **Low-Level Transport (`RawSocket`)**: Bypasses standard buffering to provide byte-level interception of `IAC` sequences. (See [ADR-0002](../adr/0002-use-rawsocket-for-byte-level-protocol-control.md))
2.  **Negotiation State Manager**: A centralized state machine that handles the `WILL/WONT/DO/DONT` handshake. It prevents negotiation loops and tracks state transitions for auditing.
3.  **Probe Interface (Plugin Architecture)**: A sandbox-based framework for RFC-specific modules (e.g., Window Size, Binary Mode). Each probe can inject sequences and monitor responses in isolation.
4.  **MUD Extension Modules**: Specialized probes for advanced features like **MCCP** (Zlib compression) and **GMCP** (JSON out-of-band data).

## The State-Machine Framework

Telnet negotiation is inherently stateful. The Sentinel architecture ensures:
- **Loop Prevention**: Detecting and breaking recursive negotiation cycles.
- **Adversarial Testing**: Programmatically simulating non-compliant behavior to test server fallbacks.
- **Traceability**: Detailed logging of every handshake transition for post-audit analysis.

## Plugin-Based Probing

Rather than a monolithic test suite, Telnet Sentinel uses a plugin architecture. Each **Probe** is responsible for:
- **Injection**: Sending specific byte sequences to the server.
- **Monitoring**: Observing the `RawSocket` for expected (or malformed) responses.
- **Validation**: Comparing server behavior against RFC standards.

## Data Flow

1.  User provides command-line arguments.
2.  `ArgParser` validates and parses these into `ArgResults`.
3.  The application branches based on flags (e.g., `--help`, `--version`, `--verbose`).
4.  Positional arguments and other options are passed to the core logic.

## Design Principles

- **Simplicity**: Favor standard Dart libraries and established patterns.
- **Transparency**: Use verbose logging to aid debugging.
- **Safety**: Ensure inputs are validated before processing.
