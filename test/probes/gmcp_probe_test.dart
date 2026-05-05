import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/probes/gmcp_probe.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

void main() {
  group('GmcpProbe', () {
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

    test('passes when server negotiates GMCP and sends a valid message', () async {
      final probe = GmcpProbe();
      
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
             // If we received IAC DO GMCP (255, 253, 201)
             for (int i = 0; i < bytes.length - 2; i++) {
               if (bytes[i] == 255 && bytes[i+1] == 253 && bytes[i+2] == 201) {
                 // Respond with IAC WILL GMCP
                 serverSideSocket.write([255, 251, 201]);
                 // Followed by IAC SB GMCP Core.Hello {} IAC SE
                 final gmcpPayload = utf8.encode('Core.Hello {}');
                 final sbMessage = [255, 250, 201, ...gmcpPayload, 255, 240];
                 serverSideSocket.write(sbMessage);
                 break;
               }
             }
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.pass);
      expect(result.message, contains('GMCP negotiation successful'));
      expect(result.message, contains('Core.Hello'));
    });

    test('fails when server refuses GMCP', () async {
      final probe = GmcpProbe();
      
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
             for (int i = 0; i < bytes.length - 2; i++) {
               if (bytes[i] == 255 && bytes[i+1] == 253 && bytes[i+2] == 201) {
                 // Respond with IAC WONT GMCP
                 serverSideSocket.write([255, 252, 201]);
                 break;
               }
             }
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Server refused GMCP'));
    });

    test('fails when server sends WILL but no SB', () async {
      final probe = GmcpProbe();
      
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
             for (int i = 0; i < bytes.length - 2; i++) {
               if (bytes[i] == 255 && bytes[i+1] == 253 && bytes[i+2] == 201) {
                 // Respond with IAC WILL GMCP but NOTHING ELSE
                 serverSideSocket.write([255, 251, 201]);
                 break;
               }
             }
          }
        }
      });

      final result = await probe.run(transport).timeout(const Duration(seconds: 10));
      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Server sent WILL GMCP but did not send any GMCP subnegotiation messages'));
    });

    test('fails when server sends malformed GMCP', () async {
      final probe = GmcpProbe();
      
      serverSideSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final bytes = serverSideSocket.read();
          if (bytes != null) {
             for (int i = 0; i < bytes.length - 2; i++) {
               if (bytes[i] == 255 && bytes[i+1] == 253 && bytes[i+2] == 201) {
                 serverSideSocket.write([255, 251, 201]);
                 // Send empty SB GMCP
                 serverSideSocket.write([255, 250, 201, 255, 240]);
                 break;
               }
             }
          }
        }
      });

      final result = await probe.run(transport);
      expect(result.status, AuditStatus.fail);
      expect(result.message, contains('Received malformed GMCP message'));
    });
  });
}
