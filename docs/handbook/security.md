# Security

This page documents security rules and operational cautions for `telnet-sentinel`.

## Core Security Rules

1.  **Secret Management**: NEVER commit secrets, API keys, or credentials to the repository.
2.  **Input Validation**: All external input (CLI arguments, files, network data) must be validated and sanitized before use.
3.  **Least Privilege**: The application should only require permissions necessary for its specific tasks.

## Sensitive Files

- `pubspec.yaml`: Contains dependency information; ensure dependencies are from trusted sources.
- [TODO: List other sensitive files as they are introduced.]

## Data Safety

- [TODO: Document how sensitive data is handled, stored, or transmitted.]

## Security Audits

Periodic security scans can be performed using relevant tools for the Dart ecosystem.
