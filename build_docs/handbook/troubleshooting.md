# Troubleshooting

This page provides guidance for known issues and debugging steps.

## Known Issues

- **Inconsistent Imports**: Mixing relative imports (`import '../models/...'`) and package imports (`import 'package:telnet_sentinel/...'`) can cause the Dart VM to treat types from the same file as distinct, leading to `type 'X' is not a subtype of 'X'` errors. Always use package imports.

## Debugging

- **Sniffer Mode**: Run with `--sniffer` to see raw IAC sequences and data flow in real-time. This is the most effective way to diagnose negotiation failures.
- **Verbose Output**: Use `--verbose` for higher-level diagnostic messages from the state manager and probes.
- **Packet Traces**: For low-level network issues, use system tools like `tcpdump` or `wireshark` alongside Telnet Sentinel.

## Common Failures

### 1. "Timeout waiting for response"
- **Cause**: The server did not respond to a negotiation request (e.g., `DO TTYPE`) within the probe's timeout (default 5s).
- **Resolution**: Verify the server supports the requested option or increase the timeout in the probe implementation if the network is highly latent.

### 2. "MCCP2 Decompression Error"
- **Cause**: The server signaled the start of MCCP2 but sent malformed Zlib data or closed the stream prematurely.
- **Resolution**: Check the server's MCCP implementation. Telnet Sentinel expects a standard Zlib stream immediately following the `IAC SB MCCP2 IAC SE` sequence.

### 3. "Negotiation Loop Detected"
- **Cause**: The server and Telnet Sentinel are repeatedly toggling the same option.
- **Resolution**: The `NegotiationStateManager` uses the RFC 1143 Q-method to prevent this. If a loop still occurs, it may indicate a non-compliant server that ignores rejection signals (`WONT`/`DONT`).
