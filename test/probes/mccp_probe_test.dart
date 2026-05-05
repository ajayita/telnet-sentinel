import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/probes/mccp_probe.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

void main() {
  group('MccpProbe', () {
    late RawServerSocket server;
    late TelnetTransport transport;
    late RawSocket serverSideSocket;

    setUp(() async {
      server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final transportFuture = RawSocket.connect(InternetAddress.loopbackIPv4, server.port)
          .then((s) => TelnetTransport(s));
      
      serverSideSocket = await server.first;
      transport = await transportFuture;
    });

    tearDown(() async {
      await transport.close();
      serverSideSocket.close();
      await server.close();
    });

    test('passes when server negotiates MCCP2 and sends compressed data', () async {
      final probe = MccpProbe();
      
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
             // If we received IAC DO MCCP2 (255, 253, 86)
             for (int i = 0; i < bytes.length - 2; i++) {
               if (bytes[i] == 255 && bytes[i+1] == 253 && bytes[i+2] == 86) {
                 // Respond with IAC WILL MCCP2
                 serverSideSocket.write([255, 251, 86]);
                 // Followed by IAC SB MCCP2 IAC SE
                 serverSideSocket.write([255, 250, 86, 255, 240]);
                 // Then some compressed data
                 final compressed = zlib.encode('Compressed content'.codeUnits);
                 serverSideSocket.write(compressed);
                 break;
               }
             }
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('MCCP2 negotiation successful'));
    });

    test('fails when server refuses MCCP2', () async {
      final probe = MccpProbe();
      
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
             for (int i = 0; i < bytes.length - 2; i++) {
               if (bytes[i] == 255 && bytes[i+1] == 253 && bytes[i+2] == 86) {
                 // Respond with IAC WONT MCCP2
                 serverSideSocket.write([255, 252, 86]);
                 break;
               }
             }
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Server refused MCCP2'));
    });

    test('fails when server sends WILL but no SB', () async {
      final probe = MccpProbe();
      
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
             for (int i = 0; i < bytes.length - 2; i++) {
               if (bytes[i] == 255 && bytes[i+1] == 253 && bytes[i+2] == 86) {
                 // Respond with IAC WILL MCCP2 but NOTHING ELSE
                 serverSideSocket.write([255, 251, 86]);
                 break;
               }
             }
          }
        }
      });

      // We expect this to timeout internally and return fail
      final result = await probe.run(transport);
      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Server sent WILL MCCP2 but did not start compression'));
    });
  });
}
