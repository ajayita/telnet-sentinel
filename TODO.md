# Project TODO

This file tracks the implementation of the Telnet Sentinel core features. For detailed instructions, see the [Core Implementation Plan](docs/superpowers/plans/2026-05-04-core-auditor-implementation.md).

## Phase 1: Foundation
- [ ] Task 1: Foundation - Transport & Basic IAC Models
    - [ ] Define Telnet Event models
    - [ ] Create TelnetTransport using RawSocket
    - [ ] Write tests for byte-stream separation

## Phase 2: State Management
- [ ] Task 2: Negotiation State Manager
    - [ ] Implement the WILL/WONT/DO/DONT state machine
    - [ ] Handle loop prevention
    - [ ] Write unit tests for state transitions

## Phase 3: Probing & Handshake
- [ ] Task 3: Probe Interface & Handshake Audit
    - [ ] Define ProbeInterface
    - [ ] Implement HandshakeProbe
    - [ ] Write tests for HandshakeProbe

## Phase 4: CLI & Reporting
- [ ] Task 4: CLI Integration & Reporting
    - [ ] Implement AuditReport model
    - [ ] Update CLI to use TelnetTransport and Probes
    - [ ] Implement human-readable console output
