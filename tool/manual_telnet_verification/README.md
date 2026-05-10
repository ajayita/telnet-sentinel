# Manual Telnet Verification

This directory contains committed manual tooling for checking the current exposed probe suite against a controlled local Telnet target.

It is not part of `dart test`, CI, package validation, pre-commit hooks, or release automation. Run it only when you have a suitable local mock server listening on `127.0.0.1:2323`.

## Target

The current script targets only:

```bash
127.0.0.1:2323
```

The local server receives the full current suite:

- `HandshakeProbe`
- `AytProbe`
- `BinaryModeProbe`
- `GmcpProbe`
- `MccpProbe`
- `MalformedIacProbe`
- `NegotiationLoopProbe`

Each probe uses a fresh `RawSocket` and `TelnetTransport`, matching the current CLI audit behavior.

## Start Or Verify The Local Server

The script does not start, embed, or replace the local mock server. Start the external mock server separately, then verify that the port is listening before running the manual check.

One simple port check is:

```bash
nc -vz 127.0.0.1 2323
```

If `nc` is unavailable, use any local socket/listener inspection tool available on the machine.

## Run

```bash
dart run tool/manual_telnet_verification/verify_telnet_targets.dart
```

Optional flags:

```bash
dart run tool/manual_telnet_verification/verify_telnet_targets.dart --debug
dart run tool/manual_telnet_verification/verify_telnet_targets.dart --target local
```

`--target local` is an explicit alias for the only supported target, `127.0.0.1:2323`.

## Interpret Output

- `PASS`: The probe returned `AuditStatus.pass`.
- `FAIL`: The probe returned `AuditStatus.fail`, the connection failed, or the local target was unreachable.
- `WARN`: The probe returned `AuditStatus.warning`.
- `TODO`: A known verification gap that is intentionally not exercised by this script.

The script exits `0` when the local full suite passes, or when only explicit TODO items remain. It exits non-zero for unexpected local probe failures or when the local mock server is unreachable.

## Public Targets

Public live smoke targets such as `telehack.com` or `mapscii.me` are intentionally not exercised by this script. The current application exposes only the full audit suite, and that suite is not safe to send to public third-party Telnet services.

## Known TODO/API Gap

Add a configurable verification mode so public targets can receive only safe smoke checks while local controlled targets can receive the full suite.
