import 'dart:io';
import 'package:test/test.dart';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/probes/malformed_iac_probe.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';

void main() {
  group('MalformedIacProbe', () {
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

    test(
      'passes when server survives malformed sequences and responds to AYT',
      () async {
        final probe = MalformedIacProbe();

        serverSideSocket.listen((event) {
          if (event == RawSocketEvent.read) {
            final bytes = serverSideSocket.read();
            if (bytes != null && bytes.contains(246)) {
              // contains AYT
              serverSideSocket.write([255, 241]); // IAC NOP
            }
          }
        });

        final result = await probe.run(transport);
        expect(result.status, AuditStatus.pass);
        expect(result.message, contains('Server remained responsive'));
      },
    );

    test(
      'fails when server closes connection after malformed sequences',
      () async {
        final probe = MalformedIacProbe();

        serverSideSocket.listen((event) {
          if (event == RawSocketEvent.read) {
            final bytes = serverSideSocket.read();
            if (bytes != null && bytes.contains(255)) {
              // Close connection on any IAC to simulate crash/closure
              serverSideSocket.close();
            }
          }
        });

        final result = await probe.run(transport);
        expect(result.status, AuditStatus.fail);
        expect(
          result.message,
          anyOf(contains('Connection closed'), contains('Connection error')),
        );
      },
    );
  });
}
