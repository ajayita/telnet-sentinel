import 'dart:io';

import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/probes/ayt_probe.dart';
import 'package:telnet_sentinel/src/probes/gmcp_probe.dart';
import 'package:telnet_sentinel/src/probes/handshake_probe.dart';
import 'package:telnet_sentinel/src/probes/malformed_iac_probe.dart';
import 'package:telnet_sentinel/src/probes/negotiation_loop_probe.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:test/test.dart';

import '../fake_servers/probe_scenario_servers.dart';

void main() {
  group('Probe scenario self-tests', () {
    test('AytProbe passes against a compliant scenario server', () async {
      final result = await _runProbe(
        CompliantProbeScenarioServer(),
        AytProbe(),
      );

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('AYT'));
    });

    test('AytProbe fails against a no-response scenario server', () async {
      final result = await _runProbe(
        NoResponseProbeScenarioServer(),
        AytProbe(),
      );

      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Timeout'));
    });

    test('HandshakeProbe passes against a compliant scenario server', () async {
      final result = await _runProbe(
        CompliantProbeScenarioServer(),
        HandshakeProbe(),
      );

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('TTYPE'));
    });

    test(
      'HandshakeProbe fails against a no-response scenario server',
      () async {
        final result = await _runProbe(
          NoResponseProbeScenarioServer(),
          HandshakeProbe(),
        );

        expect(result.status, AuditStatus.fail);
        expect(result.message, contains('Timeout'));
      },
    );

    test('GmcpProbe passes against a compliant scenario server', () async {
      final result = await _runProbe(
        CompliantProbeScenarioServer(),
        GmcpProbe(),
      );

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('Core.Hello'));
    });

    test('GmcpProbe fails against a GMCP-refusal scenario server', () async {
      final result = await _runProbe(
        GmcpRefusalProbeScenarioServer(),
        GmcpProbe(),
      );

      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('refused GMCP'));
    });

    test(
      'NegotiationLoopProbe fails against a loop-stall scenario server',
      () async {
        final result = await _runProbe(
          NegotiationLoopStallProbeScenarioServer(),
          NegotiationLoopProbe(),
        );

        expect(result.status, AuditStatus.fail);
        expect(result.message, contains('Timeout'));
      },
      timeout: const Timeout(Duration(seconds: 12)),
    );

    test(
      'MalformedIacProbe fails when target mishandles malformed input',
      () async {
        final result = await _runProbe(
          MalformedIacFailureProbeScenarioServer(),
          MalformedIacProbe(),
        );

        expect(result.status, AuditStatus.fail);
        expect(
          result.message,
          anyOf(contains('Connection closed'), contains('Connection error')),
        );
      },
    );
  });
}

Future<AuditResult> _runProbe(ProbeScenarioServer server, Probe probe) async {
  await server.bind();
  final socket = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  final transport = TelnetTransport(socket);

  try {
    return await probe.run(transport);
  } finally {
    await transport.close();
    await server.close();
  }
}
