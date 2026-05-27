import 'dart:async';
import 'dart:typed_data';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';

class MalformedIacProbe implements Probe {
  @override
  String get name => 'Malformed IAC Probe';

  @override
  Future<AuditResult> run(TelnetTransport transport) async {
    final completer = Completer<AuditResult>();

    final subscription = transport.events.listen(
      (event) {
        if (!completer.isCompleted) {
          // If we get any response after our malformed sequence + AYT, it means server survived.
          completer.complete(
            AuditResult(
              name,
              AuditStatus.pass,
              'Server remained responsive after malformed IAC sequences. Received: ${event.type}',
            ),
          );
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.complete(
            AuditResult(
              name,
              AuditStatus.fail,
              'Connection error after malformed IAC sequences: $error',
            ),
          );
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(
            AuditResult(
              name,
              AuditStatus.fail,
              'Connection closed after malformed IAC sequences.',
            ),
          );
        }
      },
    );

    try {
      // 1. Partial IAC
      transport.write(Uint8List.fromList([255]));
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Invalid command (100)
      transport.write(Uint8List.fromList([255, 100]));
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Unclosed SB
      transport.write(Uint8List.fromList([255, 250, 1, 2, 3]));
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. AYT to check responsiveness
      transport.write(Uint8List.fromList([255, 246]));

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return AuditResult(
            name,
            AuditStatus.fail,
            'Timeout waiting for response after malformed sequences.',
          );
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        return AuditResult(
          name,
          AuditStatus.fail,
          'Timeout waiting for response after malformed sequences.',
        );
      }
      return AuditResult(
        name,
        AuditStatus.fail,
        'Exception during Malformed IAC probe: $e',
      );
    } finally {
      await subscription.cancel();
    }
  }
}
