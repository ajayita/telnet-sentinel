# ADR-0001: Adopt Repository Documentation Architecture

## Status

Accepted

## Context

The repository lacked a structured way to maintain long-term architecture, design decisions, and developer guidance. This often leads to "context drift" where agents and humans must infer intent from source code alone, which is error-prone and inefficient.

## Decision

We are adopting a functionally lossless, lightweight documentation architecture:

1.  **README.md**: Entry point and orientation.
2.  **CHANGELOG.md**: Record of completed changes.
3.  **AGENTS.md**: Instructions and conventions for AI assistants.
4.  **docs/handbook/**: Authoritative current system explanation.
5.  **docs/adr/**: Durable record of significant design decisions.
6.  **docs/working-notes/**: Non-authoritative scratch space for research and planning.

## Alternatives Considered

- **Flat documentation in README**: Becomes too large and difficult to navigate.
- **Wiki**: Separate from source control, making it hard to keep in sync with code changes.
- **No structured documentation**: Relies on source code inspection, which lacks rationale and high-level context.

## Consequences

- **Maintenance**: Documentation must be updated alongside code changes.
- **Clarity**: Significant decisions and current architecture are explicitly recorded.
- **Onboarding**: New developers and AI agents can quickly understand the system through progressive context loading.
- **Consistency**: Future work must align with accepted ADRs and Handbook guidance.
