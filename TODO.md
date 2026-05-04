# Project TODO

This file tracks the implementation of the Telnet Sentinel core features. For detailed instructions, see the [Core Implementation Plan](docs/superpowers/plans/2026-05-04-core-auditor-implementation.md).

## Phase 1: Foundation
- [x] Task 1: Foundation - Transport & Basic IAC Models
    - [x] Define Telnet Event models
    - [x] Create TelnetTransport using RawSocket
    - [x] Write tests for byte-stream separation

## Phase 2: State Management
- [x] Task 2: Negotiation State Manager
    - [x] Implement the WILL/WONT/DO/DONT state machine
    - [x] Handle loop prevention
    - [x] Write unit tests for state transitions

## Phase 3: Probing & Handshake
- [x] Task 3: Probe Interface & Handshake Audit
    - [x] Define ProbeInterface
    - [x] Implement HandshakeProbe
    - [x] Write tests for HandshakeProbe

## Phase 4: CLI & Reporting
- [x] Task 4: CLI Integration & Reporting
    - [x] Implement AuditReport model
    - [x] Update CLI to use TelnetTransport and Probes
    - [x] Implement human-readable console output
