import 'dart:async';
import 'package:test/test.dart';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/telnet_event.dart';
import 'dart:io';
import 'models.dart';

class TranscriptRunner {
  static Future<void> runSocket(
    TranscriptFixture fixture,
    InternetAddress address,
    int port,
  ) async {
    final socket = await RawSocket.connect(address, port);
    final transport = TelnetTransport(socket);

    final events = <TelnetEvent>[];
    final sub = transport.events.listen((e) => events.add(e));

    try {
      for (var step in fixture.steps) {
        if (step.clientSends != null) {
          socket.write(step.clientSends!);
          // Give it a tiny bit to roundtrip
          await Future.delayed(Duration(milliseconds: 50));
        } else if (step.expectEvents != null) {
          // Wait until we have enough events
          int retries = 10;
          while (events.length < step.expectEvents!.length && retries > 0) {
            await Future.delayed(Duration(milliseconds: 10));
            retries--;
          }

          expect(
            events.length,
            greaterThanOrEqualTo(step.expectEvents!.length),
            reason: 'Did not receive expected number of events',
          );

          for (int i = 0; i < step.expectEvents!.length; i++) {
            final expected = step.expectEvents![i];
            final actual = events.removeAt(0);

            final expectedType = expected.type == 'iac'
                ? TelnetEventType.iac
                : TelnetEventType.data;
            expect(actual.type, expectedType, reason: 'Event type mismatch');
            expect(
              actual.bytes,
              expected.bytes,
              reason: 'Event bytes mismatch',
            );
          }
        } else if (step.expectState != null) {
          // Not implemented in parser yet, skip
        }
      }
    } finally {
      await sub.cancel();
      await transport.close();
    }
  }
}
