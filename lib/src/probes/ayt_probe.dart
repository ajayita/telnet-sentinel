import 'dart:async';
import 'dart:typed_data';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/models/telnet_event.dart';
import 'package:telnet_sentinel/src/state/negotiation_state_manager.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';

class AytProbe implements Probe {
  @override
  String get name => 'AYT Probe';

  @override
  Future<AuditResult> run(TelnetTransport transport) async {
    final completer = Completer<AuditResult>();

    final stateManager = NegotiationStateManager(
      onSend: (bytes) => transport.write(bytes),
    );

    final subscription = transport.events.listen(
      (event) {
        if (!completer.isCompleted) {
          if (event.type == TelnetEventType.iac) {
            stateManager.handleCommand(event.bytes);
            completer.complete(
              AuditResult(
                name,
                AuditStatus.pass,
                'Server responded to AYT with a Telnet command: ${event.bytes}',
              ),
            );
          } else if (event.type == TelnetEventType.data) {
            completer.complete(
              AuditResult(
                name,
                AuditStatus.pass,
                'Server responded to AYT with data.',
              ),
            );
          }
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.complete(
            AuditResult(
              name,
              AuditStatus.fail,
              'Error during AYT probe: $error',
            ),
          );
        }
      },
    );

    try {
      // Send IAC AYT (255, 246)
      transport.write(Uint8List.fromList([255, 246]));

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return AuditResult(
            name,
            AuditStatus.fail,
            'Timeout waiting for AYT response.',
          );
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        return AuditResult(
          name,
          AuditStatus.fail,
          'Timeout waiting for AYT response.',
        );
      }
      return AuditResult(
        name,
        AuditStatus.fail,
        'Exception during AYT probe: $e',
      );
    } finally {
      await subscription.cancel();
    }
  }
}
