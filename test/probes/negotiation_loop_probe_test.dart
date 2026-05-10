import 'dart:io';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/probes/negotiation_loop_probe.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

void main() {
  group('NegotiationLoopProbe', () {
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

    test('passes when server toggles negotiation correctly', () async {
      final probe = NegotiationLoopProbe();

      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
            // Check for DO ECHO (255, 253, 1) -> respond WILL ECHO (255, 251, 1)
            for (int i = 0; i < bytes.length - 2; i++) {
              if (bytes[i] == 255 && bytes[i + 1] == 253 && bytes[i + 2] == 1) {
                serverSideSocket.write([255, 251, 1]);
              }
              // Check for DONT ECHO (255, 254, 1) -> respond WONT ECHO (255, 252, 1)
              if (bytes[i] == 255 && bytes[i + 1] == 254 && bytes[i + 2] == 1) {
                serverSideSocket.write([255, 252, 1]);
              }
            }
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('Successfully toggled'));
    });

    test('fails on timeout if server stops responding', () async {
      final probe = NegotiationLoopProbe();

      int count = 0;
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
            if (count < 2) {
              // Only respond a few times
              for (int i = 0; i < bytes.length - 2; i++) {
                if (bytes[i] == 255 &&
                    bytes[i + 1] == 253 &&
                    bytes[i + 2] == 1) {
                  serverSideSocket.write([255, 251, 1]);
                  count++;
                }
              }
            }
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Timeout'));
    });
  });
}
