# ADR-0003: Complement Fixtures With Probe Scenario Tests

## Status

Accepted

## Context

The fixture-based conformance suite is the canonical self-test architecture for
byte-level transcript behavior. YAML fixtures in `test/golden/` run through
`FixtureParser` and `TranscriptRunner` against loopback fake servers so the
project can verify exact Telnet byte sequences and mutation targets.

Probe implementations also need end-to-end validation against realistic
loopback targets. These checks exercise the complete probe flow through
`TelnetTransport`, `NegotiationStateManager`, and fake server behavior, but they
are not a replacement for fixture transcript validation.

## Decision

Keep the fixture-based conformance suite as the authoritative byte-level
transcript harness. Add a separate probe scenario test layer for full probe
behavior against purpose-built loopback `RawSocket` servers.

Probe scenario helpers must use names that distinguish them from fixture
servers. The existing fixture `GoodServer` remains the transcript fixture target
and must not be repurposed as a general probe compliance server.

## Alternatives Considered

- **Replace fixtures with probe scenario tests**: Rejected because probe-level
  tests do not preserve exact expected transcript assertions or fixture parser
  coverage.
- **Keep only per-probe unit tests**: Rejected because inline server behavior in
  individual unit tests does not provide a reusable end-to-end scenario layer.
- **Merge fixture and probe helper semantics**: Rejected because it would make
  the fixture harness less explicit and blur byte-level conformance with
  high-level probe behavior.

## Consequences

- The test suite now has two complementary loopback server styles:
  fixture servers for transcript conformance and probe scenario servers for
  end-to-end probe behavior.
- New probe scenarios should be additive and should not delete or weaken
  `test/infrastructure/`, `test/golden/`, or fixture fake servers.
- Documentation and test names must make the distinction clear so future changes
  do not accidentally collapse the two approaches.
