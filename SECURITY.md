# Security Policy

The `telnet_sentinel` package handles raw network traffic, including protocol handshakes and potentially sensitive MUD data (like GMCP JSON payloads).

- **Data Handling:** Users should avoid logging raw sniffed data in production environments, as it may contain credentials or sensitive user data in plaintext.
- **Reporting:** To report a security issue, contact the repository maintainer privately using the contact information available on the repository profile. Please do not open a public issue for security vulnerabilities.
