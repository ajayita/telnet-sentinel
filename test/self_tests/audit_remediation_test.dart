import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:telnet_sentinel/telnet_sentinel.dart';

void main() {
  group('Remediation Coverage Tests', () {
    test('Pre-flight check reachability failure aborts immediately', () async {
      // Connect to a dead host/port that should fail immediately
      final auditor = TelnetAuditor(
        host: '127.0.0.1',
        port: 9999, // Unlikely to be open
        connectionTimeout: const Duration(milliseconds: 50),
      );

      final report = await auditor.runSuite();
      expect(report.results.length, 1);
      expect(report.results.first.probeName, 'Pre-Flight Connection Check');
      expect(report.results.first.status, AuditStatus.fail);
      expect(report.results.first.message, contains('Host unreachable or connection refused'));
    });

    test('NegotiationStateManager rate-limits and halts replies on loops', () async {
      final sentPackets = <Uint8List>[];
      final manager = NegotiationStateManager(
        onSend: (bytes) => sentPackets.add(bytes),
      );

      // Alternating handle WILL and WONT rapidly 30 times
      for (int i = 0; i < 15; i++) {
        manager.handleCommand([255, 251, 1]); // WILL ECHO (normally triggers DO)
        manager.handleCommand([255, 252, 1]); // WONT ECHO (normally triggers DONT)
      }

      // We expect the manager to rate limit and stop replying after 20 packets (the safety threshold)
      expect(sentPackets.length, 20);
    });

    test('Welcome-banner immunity in AytProbe', () async {
      final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final transportFuture = RawSocket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
      ).then((s) => TelnetTransport(s));

      final serverSideSocket = await server.first;
      final transport = await transportFuture;

      final probe = AytProbe();

      // Immediately write a welcome banner *before* AytProbe sends anything
      serverSideSocket.write(Uint8List.fromList('Welcome banner\r\n'.codeUnits));

      // After 300ms, write response to AYT
      Timer(const Duration(milliseconds: 300), () {
        serverSideSocket.write(Uint8List.fromList('Yes, here\r\n'.codeUnits));
      });

      final result = await probe.run(transport);

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('Server responded to AYT with data'));

      await transport.close();
      serverSideSocket.close();
      await server.close();
    });

    test('Welcome-banner immunity in MalformedIacProbe', () async {
      final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final transportFuture = RawSocket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
      ).then((s) => TelnetTransport(s));

      final serverSideSocket = await server.first;
      final transport = await transportFuture;

      final probe = MalformedIacProbe();

      // Immediately write welcome banner
      serverSideSocket.write(Uint8List.fromList('Welcome banner\r\n'.codeUnits));

      // Wait for malformed sequences to arrive, then write response
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null && bytes.contains(246)) { // contains AYT
            serverSideSocket.write(Uint8List.fromList('Responsive\r\n'.codeUnits));
          }
        }
      });

      final result = await probe.run(transport);

      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('Server remained responsive after malformed IAC sequences'));

      await transport.close();
      serverSideSocket.close();
      await server.close();
    });

    test('AuditResult tracks latency and rawBytesExchanged correctly', () async {
      final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final auditor = TelnetAuditor(
        host: '127.0.0.1',
        port: server.port,
        customProbes: [HandshakeProbe()],
      );

      // Run server in background to respond to handshake
      server.listen((client) {
        client.listen((event) {
          if (event == RawSocketEvent.read) {
            final bytes = client.read();
            if (bytes != null && bytes.contains(24)) { // TTYPE DO
              client.write([255, 251, 24]); // WILL TTYPE
            }
          }
        });
      });

      final report = await auditor.runSuite();
      expect(report.results.isNotEmpty, true);
      
      final handshakeResult = report.results.first;
      expect(handshakeResult.status, AuditStatus.pass);
      expect(handshakeResult.latency, isNot(Duration.zero));
      expect(handshakeResult.rawBytesExchanged, isNotNull);
      expect(handshakeResult.rawBytesExchanged!.isNotEmpty, true);

      // Verify JSON serialization includes the new timing and raw bytes fields
      final json = handshakeResult.toJson();
      expect(json['latency_ms'], isNotNull);
      expect(json['rawBytesExchanged'], isNotNull);

      await server.close();
    });
  });
}
