# Architecture Decision Records (ADRs)

Architecture Decision Records (ADRs) are used to record significant design decisions, the context in which they were made, and the consequences of those decisions.

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
