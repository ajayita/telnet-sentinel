import 'dart:io';
import 'package:test/test.dart';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/probes/ayt_probe.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';

void main() {
  group('AytProbe', () {
    late RawServerSocket server;
    late TelnetTransport transport;
    late RawSocket serverSideSocket;

    setUp(() async {
      server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final transportFuture = RawSocket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
      ).then((s) => TelnetTransport(s));

      serverSideSocket = await server.first;
      transport = await transportFuture;
    });

    tearDown(() async {
      await transport.close();
      serverSideSocket.close();
      await server.close();
    });

    test('passes when server responds with data', () async {
      final probe = AytProbe();

      bool responded = false;
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read && !responded) {
          final bytes = serverSideSocket.read();
          if (bytes != null && bytes.contains(246)) {
            // contains AYT
            serverSideSocket.write('Yes, I am here'.codeUnits);
            responded = true;
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('Server responded to AYT with data'));
    });

    test('passes when server responds with a command', () async {
      final probe = AytProbe();

      bool responded = false;
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read && !responded) {
          final bytes = serverSideSocket.read();
          if (bytes != null && bytes.contains(246)) {
            serverSideSocket.write([255, 241]); // IAC NOP
            responded = true;
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.pass);
      expect(
        result.message,
        contains('Server responded to AYT with a Telnet command'),
      );
    });

    test('fails on timeout', () async {
      final probe = AytProbe();
      // No server response

      final result = await probe
          .run(transport)
          .timeout(
            Duration(seconds: 6),
            onTimeout: () {
              // This should be handled by the probe's internal timeout
              return AuditResult(
                'timeout',
                AuditStatus.fail,
                'External timeout',
              );
            },
          );

      // We set timeout to 5 seconds in the probe, so it should fail.
      // Note: In real test we might want to use a shorter timeout for faster tests if we had configurable timeouts.
      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Timeout'));
    });
  });
}
