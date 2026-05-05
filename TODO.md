# Project TODO

This file tracks the implementation of the Telnet Sentinel core features.

## Phase 1: Foundation (COMPLETE)
- [x] Task 1: Foundation - Transport & Basic IAC Models
- [x] Task 2: Negotiation State Manager
- [x] Task 3: Probe Interface & Handshake Audit
- [x] Task 4: CLI Integration & Reporting

## Phase 5: Exhaustive Core Telnet Implementation (RFC 854) (COMPLETE)
- [x] **Task 5.1: Core Command Handling**
- [x] **Task 5.2: Advanced Sub-negotiation (SB/SE)**
- [x] **Task 5.3: Core Protocol Probes**
- [x] **Task 5.4: Stress & Adversarial Testing**

## Phase 6: MUD Extensions (IN PROGRESS)
- [x] **Task 6.1: MCCP (Zlib Compression)**
- [ ] **Task 6.2: GMCP/MSDP (Out-of-band Data)**
    - [ ] Implement JSON parser for GMCP
    - [ ] Implement `GmcpProbe` to verify structured data leakage

## Phase 7: UI & Reporting Enhancements (PLANNED)
- [ ] **Task 7.1: JSON Output**
    - [ ] Implement `--json` flag for machine-readable reports
- [ ] **Task 7.2: Traffic Visualizer**
    - [ ] Implement a live traffic view showing IAC handshakes in real-time
