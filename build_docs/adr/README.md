# Architecture Decision Records (ADRs)

Architecture Decision Records (ADRs) are used to record significant design decisions, the context in which they were made, and the consequences of those decisions.

## Index of ADRs

- [ADR-0001: Adopt Repository Documentation Architecture](0001-adopt-repository-documentation-architecture.md) - Accepted
- [ADR-0002: Use RawSocket for Byte-Level Protocol Control](0002-use-rawsocket-for-byte-level-protocol-control.md) - Accepted
- [ADR-0003: Complement Fixtures with Probe Scenario Tests](0003-complement-fixtures-with-probe-scenario-tests.md) - Accepted
- [ADR-0004: Remediate Adversarial Audit Findings and Introduce TelnetAuditor Facade](0004-remediate-audit-findings-and-introduce-telnet-auditor.md) - Accepted
- [ADR-0005: Remediate Pre-Publication Adversarial Audit Findings](0005-remediate-adversarial-audit-findings.md) - Accepted

---

## When to Create an ADR

Create an ADR when you make a significant technical decision that:
- Affects the long-term architecture of the project.
- Chooses one framework, runtime, or database over another.
- Adopts a specific project structure or convention.
- Defines a security, compatibility, or concurrency policy.
- Changes a public API or internal boundary.

## Filename Format

`NNNN-short-decision-title.md` (e.g., `0001-adopt-repository-documentation-architecture.md`)

## Status Values

- **Proposed**: The decision is being discussed.
- **Accepted**: The decision has been agreed upon and implemented.
- **Superseded**: A newer ADR has replaced this decision.
- **Deprecated**: The decision is no longer relevant or recommended.
- **Rejected**: The decision was considered but not adopted.

## ADR Template

```markdown
# ADR-NNNN: Decision Title

## Status

[Status: Proposed | Accepted | Superseded | Deprecated | Rejected]

## Context

Describe the problem, constraint, or design pressure that made the decision necessary.

## Decision

Describe the chosen approach.

## Alternatives Considered

Describe the main alternatives and why they were not chosen.

## Consequences

Describe the benefits, drawbacks, compatibility effects, maintenance implications, and future constraints created by this decision.
```
