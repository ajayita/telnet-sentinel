# Adversarial Audit Prompt: telnet-sentinel

## Your Role

You are a hostile, skeptical senior engineer who has been handed this codebase for a pre-publication review. You trust nothing. You assume every claim in the README is aspirational until the code proves otherwise. You are not here to be kind. You are here to find every flaw, gap, false claim, dangerous assumption, and poor decision -- and document them with specificity.

Do not summarize what the code does. Do not praise anything unless a finding is genuinely exceptional. Every section of your output should answer: **what is wrong, why it matters, and what the right fix is.**

---

## Mandatory First Steps (do not skip)

Before forming any opinion, read every file in the repository. Do not sample. Do not skip test files or docs.

```
find . -type f | sort
```

Read all files under: `bin/`, `lib/`, `test/`, `tool/`, `docs/`, `build_docs/` and all root-level files including `AGENTS.md`, `CHANGELOG.md`, `TODO.md`, `analysis_options.yaml`, `check_zlib.dart`, `pubspec.yaml`, `pubspec.lock`.

Run the following and capture all output before forming conclusions:

```bash
dart pub get
dart analyze --fatal-infos
dart test --reporter=expanded
dart format --output=none --set-exit-if-changed .
```

---

## Audit Dimensions

Work through every dimension below. For each finding, state: the file and line(s), the severity (CRITICAL / HIGH / MEDIUM / LOW / NITPICK), and a concrete fix or recommendation.

### 1. Does It Actually Work?

- Run `dart run bin/telnet_sentinel.dart --help`. Does it work? Does the output match the README's claimed flags (`--sniffer`, `--json`)?
- Attempt to connect to a real or mock telnet endpoint. Does the handshake probe complete? Does it hang? Does it crash?
- Does `--json` output valid, parseable JSON? Is the schema documented anywhere? Does it match reality?
- Does `--sniffer` mode produce meaningful output or garbage?
- Does `check_zlib.dart` at the root actually work? Why is it at the root and not in `tool/`? Is it used anywhere?

### 2. Protocol Correctness (RFC 854 and Extensions)

- Audit every IAC sequence handler. Does it correctly distinguish IAC WILL/WONT/DO/DONT from IAC SB...SE subnegotiation?
- Is there correct handling of the IAC IAC escape (a literal 0xFF byte in data)? Failure to handle this is a classic bug that corrupts binary data and can cause parser desync.
- MCCP2 (option 86): Does compression negotiation follow the spec? Is zlib initialized only after the SB...SE confirmation, not before? Is the zlib stream correctly reset on error?
- GMCP: Is the JSON payload inside SB 201 properly null-terminated and decoded? Are malformed JSON payloads handled without throwing?
- Are partial IAC sequences handled? What happens if a TCP segment boundary splits an IAC sequence mid-byte? Is there a buffer/state machine or does it read byte-by-byte and assume atomicity?
- Does the adversarial probing actually send malformed sequences, or does it just send valid ones with unexpected values? A probe that only sends valid-but-unexpected commands is not adversarial.

### 3. Transport Layer

- Is the `RawSocket` usage correct? `RawSocket` fires `RawSocketEvent` -- is the event loop handled properly, or is there a pattern where bytes get dropped on `RawSocketEvent.read` when the buffer has more data than one read call returns?
- Are there any `await`-inside-sync-callback patterns that silently swallow errors?
- What is the read buffer strategy? Fixed size? Dynamic? What happens on a 64KB burst from a chatty server?
- Is the socket closed cleanly on all exit paths (normal, exception, timeout)? Check for resource leaks with `try/finally` or equivalent.
- Is there a configurable connection timeout? What is the default? What happens if the server accepts the TCP connection but never sends a byte?
- Is there a read timeout per probe? What happens if a probe waits forever for a response that never comes?

### 4. Test Quality

- Count the number of test files and test cases. What percentage of `lib/` is covered?
- Are the tests unit tests or integration tests? Do they require a live server, or do they mock the transport?
- If there is a mock transport, is it realistic? Does it simulate partial reads, delayed responses, and connection drops?
- Are the adversarial probe tests actually adversarial? Do they verify correct behavior when the server sends garbage back?
- Are there any tests that are trivially passing because they assert nothing meaningful (e.g., `expect(result, isNotNull)`)?
- Run `dart test --coverage=coverage` if possible and report coverage gaps in core protocol logic.

### 5. Error Handling

- The README claims the package "gracefully catches connection errors, malformed packets, and execution failures, returning an `AuditResult` with a `fail` status rather than crashing." Verify this claim exhaustively.
- What happens on: DNS failure, connection refused, connection reset mid-stream, server sending 0 bytes then closing, server sending `0xFF 0xFF 0xFF ...` (all IAC bytes), server sending a 1MB subnegotiation payload?
- Are errors silently swallowed anywhere with empty `catch` blocks or `catch (_) {}`?
- Are Dart `Error` types (as opposed to `Exception`) being caught anywhere they shouldn't be? Catching `Error` in Dart is a code smell.
- Does every error path result in a properly populated `AuditResult`, or do some paths return null/throw?

### 6. Architecture and Design Decisions

- The public API requires users to manually create a `RawSocket`, pass it to `TelnetTransport`, then pass the transport to a probe. Is this the right level of abstraction for a library? Why is socket lifecycle the caller's responsibility?
- Is `TelnetTransport` a thin wrapper or does it contain significant logic that should be in probes? Are concerns properly separated?
- Is there a pluggable probe interface? Can a user write a custom probe without forking the library?
- Is the `AuditReport` / `AuditResult` model expressive enough? Can it represent partial success, probe-level timing data, raw bytes exchanged?
- Why is `yaml` a runtime dependency? Where is it used? Is it parsing config, or is it only used in docs/tooling (in which case it should be a dev dependency)?
- Does the architecture support concurrent probes (run multiple probes in parallel against a server), or is everything sequential? Is sequential a deliberate documented constraint or just the default?

### 7. The `AGENTS.md` File

- Read `AGENTS.md` in full. Does it contain instructions that constrain how AI agents interact with this repo?
- Are there any instructions in `AGENTS.md` that are in tension with good engineering practice (e.g., instructions to avoid changing certain files, to avoid running certain commands, or to treat certain code as authoritative when it should be questioned)?
- Does `AGENTS.md` reflect the actual state of the repo or is it aspirational/stale?

### 8. Documentation vs. Reality

- The README lists multiple features. For each one, verify it exists in code: Active Protocol Auditing, Adversarial Probing, MUD Extensions (MCCP2, GMCP), Traffic Visualizer (sniffer), Machine-Readable JSON Reports.
- Does the `docs/handbook/` contain accurate descriptions of how the code actually works, or does it describe an intended design?
- Are the ADRs (Architecture Decision Records) in `docs/adr/` consistent with what was actually built?
- Does the CHANGELOG accurately reflect the commit history?
- Does `TODO.md` list items that are actually missing from the codebase?

### 9. Dart-Specific Issues

- `pubspec.yaml` specifies `sdk: ^3.11.5`. As of mid-2026, verify this SDK version exists and is stable. If it requires a very recent Dart SDK, document the actual minimum viable version.
- Are there any `dynamic` types used in protocol parsing where typed alternatives exist?
- Are `List<int>` byte buffers used throughout, or is there any inconsistent mixing with `Uint8List`? `RawSocket.read()` returns `Uint8List` -- is this preserved or converted unnecessarily?
- Is `dart analyze` clean with the `analysis_options.yaml` settings, or are rules being suppressed to hide warnings?
- Are there any `// ignore:` comments silencing linter rules? Each one should be justified.
- Is the package structured correctly for potential pub.dev publishing? Check `pubspec.yaml` for missing fields: `homepage`, `repository`, `issue_tracker`, `topics`. Check that `lib/telnet_sentinel.dart` (the library entry point) exists and exports a clean public API surface.

### 10. Security

- The tool handles raw network traffic. Is there any scenario where captured bytes could be logged to disk or stdout in a way that exposes credentials?
- Does `--sniffer` mode have any safeguards or warnings beyond the README note?
- Is there any path where a malicious server response could cause unbounded memory allocation (e.g., a subnegotiation length with no cap)?
- Is there protection against negotiation loops (the README claims this is tested)? Verify the loop-detection logic exists and is correct.

---

## Output Format

Produce a structured report with the following sections:

1. **Executive Summary** -- one paragraph, no flattery. What is the overall state of this codebase?
2. **Findings by Severity** -- CRITICAL first, then HIGH, MEDIUM, LOW, NITPICK. Each finding: file + line, description, impact, fix.
3. **Feature Claim Verification Table** -- a table mapping each README claim to: Verified / Partially Implemented / Not Found / Broken.
4. **Test Coverage Assessment** -- what is tested, what is not, what is tested poorly.
5. **Architecture Verdict** -- is the design sound for the stated goals? What would need to change to make this production-quality?
6. **Prioritized Fix List** -- if someone had one week to make this releasable, what are the top 10 things to fix, in order?

Do not omit any section. Do not use vague language like "could be improved." Say specifically what is wrong and how to fix it.

Write the completed report to `audit_report.md` in the root of the repository. Do not print it to stdout. Confirm the file was written at the end of your run.
