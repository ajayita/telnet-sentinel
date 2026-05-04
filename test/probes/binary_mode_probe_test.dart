import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/probes/binary_mode_probe.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

void main() {
  group('BinaryModeProbe', () {
    late RawServerSocket server;
    late TelnetTransport transport;
    late RawSocket clientSocket;

    setUp(() async {
      server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final transportFuture = RawSocket.connect(InternetAddress.loopbackIPv4, server.port)
          .then((s) => TelnetTransport(s));
      
      clientSocket = await server.first;
      transport = await transportFuture;
    });

    tearDown(() async {
      await transport.close();
      clientSocket.close();
      await server.close();
    });

    test('returns pass when server responds with WILL BINARY', () async {
      final probe = BinaryModeProbe();
      
      clientSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = clientSocket.read();
          // Expect IAC DO BINARY (255 253 0)
          if (bytes != null && bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 253 && bytes[2] == 0) {
            clientSocket.write([255, 251, 0]);
          }
        }
      });

      final result = await probe.run(transport);

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('WILL BINARY'));
    });

    test('returns pass when server responds with WONT BINARY', () async {
      final probe = BinaryModeProbe();
      
      clientSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = clientSocket.read();
          // Expect IAC DO BINARY (255 253 0)
          if (bytes != null && bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 253 && bytes[2] == 0) {
            clientSocket.write([255, 252, 0]);
          }
        }
      });

      final result = await probe.run(transport);

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('WONT BINARY'));
    });

    test('returns fail on timeout', () async {
      final probe = BinaryModeProbe();
      
      final result = await probe.run(transport);

      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Timeout'));
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}
