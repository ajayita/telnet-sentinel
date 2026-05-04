import 'dart:io';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/probes/handshake_probe.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

void main() {
  group('HandshakeProbe', () {
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

    test('returns pass when server responds with WILL TTYPE', () async {
      final probe = HandshakeProbe();
      
      clientSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = clientSocket.read();
          if (bytes != null && bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 253 && bytes[2] == 24) {
            clientSocket.write([255, 251, 24]);
          }
        }
      });

      final result = await probe.run(transport);

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('WILL'));
    });

    test('returns pass when server responds with WONT TTYPE', () async {
      final probe = HandshakeProbe();
      
      clientSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = clientSocket.read();
          if (bytes != null && bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 253 && bytes[2] == 24) {
            clientSocket.write([255, 252, 24]);
          }
        }
      });

      final result = await probe.run(transport);

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('WONT'));
    });

    test('returns fail on timeout', () async {
      // Create a probe with a very short timeout for testing if possible, 
      // but since it's hardcoded to 5s, we'll just have to wait or mock it.
      // For now, let's just wait since 5s is not that long.
      final probe = HandshakeProbe();
      
      final result = await probe.run(transport);

      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Timeout'));
    }, timeout: Timeout(Duration(seconds: 10)));
  });
}
