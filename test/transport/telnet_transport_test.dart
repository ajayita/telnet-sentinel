import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:telnet_sentinel/models/telnet_event.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';

void main() {
  group('TelnetTransport', () {
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

    test('separates data and IAC sequences', () async {
      final events = <TelnetEvent>[];
      final completer = Completer<void>();
      
      transport.events.listen((event) {
        events.add(event);
        if (events.length == 2) {
          completer.complete();
        }
      });

      // Send mixed data
      // IAC WILL ECHO (0xFF 0xFB 0x01) + "Hello"
      clientSocket.write([0xFF, 0xFB, 0x01, ...'Hello'.codeUnits]);

      await completer.future.timeout(Duration(seconds: 2));

      expect(events.length, 2);
      expect(events[0].type, TelnetEventType.iac);
      expect(events[0].bytes, [0xFF, 0xFB, 0x01]);
      expect(events[1].type, TelnetEventType.data);
      expect(events[1].bytes, 'Hello'.codeUnits);
    });

    test('handles multiple IAC sequences and split data', () async {
      final events = <TelnetEvent>[];
      final completer = Completer<void>();
      
      transport.events.listen((event) {
        events.add(event);
        if (events.length == 4) {
          completer.complete();
        }
      });

      // Send: "Hi" + IAC DO ECHO (0xFF 0xFD 0x01) + "!" + IAC WILL SUPPRESS GO AHEAD (0xFF 0xFB 0x03)
      clientSocket.write('Hi'.codeUnits);
      clientSocket.write([0xFF, 0xFD, 0x01]);
      clientSocket.write('!'.codeUnits);
      clientSocket.write([0xFF, 0xFB, 0x03]);

      await completer.future.timeout(Duration(seconds: 2));

      expect(events.length, 4);
      expect(events[0].type, TelnetEventType.data);
      expect(events[0].bytes, 'Hi'.codeUnits);
      expect(events[1].type, TelnetEventType.iac);
      expect(events[1].bytes, [0xFF, 0xFD, 0x01]);
      expect(events[2].type, TelnetEventType.data);
      expect(events[2].bytes, '!'.codeUnits);
      expect(events[3].type, TelnetEventType.iac);
      expect(events[3].bytes, [0xFF, 0xFB, 0x03]);
    });

    test('handles subnegotiation (SB...SE)', () async {
      final events = <TelnetEvent>[];
      final completer = Completer<void>();
      
      transport.events.listen((event) {
        events.add(event);
        if (events.length == 3) {
          completer.complete();
        }
      });

      // Send: "Data" + SB 24 ... IAC SE + "More"
      clientSocket.write('Data'.codeUnits);
      clientSocket.write([0xFF, 0xFA, 0x18, 0x00, 0xFF, 0xF0]);
      clientSocket.write('More'.codeUnits);

      await completer.future.timeout(Duration(seconds: 2));

      expect(events.length, 3);
      expect(events[0].type, TelnetEventType.data);
      expect(events[0].bytes, 'Data'.codeUnits);
      expect(events[1].type, TelnetEventType.iac);
      expect(events[1].bytes, [0xFF, 0xFA, 0x18, 0x00, 0xFF, 0xF0]);
      expect(events[2].type, TelnetEventType.data);
      expect(events[2].bytes, 'More'.codeUnits);
    });
  });
}
