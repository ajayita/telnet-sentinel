# Development Workflow

This page explains the expected workflow for contributing to `telnet-sentinel`.

## Making Changes

1.  **Research**: Understand the current implementation and documentation.
2.  **Update Documentation**: If the change affects architecture or behavior, update the relevant Handbook page or create an ADR.
3.  **Implement**: Write the code change.
4.  **Test**: Add or update tests in `test/` and ensure all tests pass.
5.  **Verify**: Run `dart analyze` and `dart format`.
6.  **Record**: Update `CHANGELOG.md` with a summary of the change.

## Documentation Update Rules

- **Handbook**: Update if you change *how* the system works or *how* developers should work with it.
- **ADRs**: Create if you make or change a *significant* technical decision.
- **README**: Update if you change installation, usage, or project status.
- **CHANGELOG**: Update for every meaningful change.
- **AGENTS.md**: Update if you establish a new convention or boundary that AI assistants must follow.

## Progressive Context Loading

When starting a new task, follow this order to gather context:
1.  Root `AGENTS.md`.
2.  `README.md`.
3.  Relevant Handbook pages.
4.  Relevant ADRs.
5.  Folder-level `AGENTS.md` files.
6.  Source code.
