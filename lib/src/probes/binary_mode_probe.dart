import 'dart:async';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/models/telnet_event.dart';
import 'package:telnet_sentinel/src/state/negotiation_state_manager.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';

class BinaryModeProbe implements Probe {
  @override
  String get name => 'Binary Mode Audit';

  @override
  Future<AuditResult> run(TelnetTransport transport) async {
    final completer = Completer<AuditResult>();

    final stateManager = NegotiationStateManager(
      onSend: (bytes) => transport.write(bytes),
    );

    final subscription = transport.events.listen(
      (event) {
        if (completer.isCompleted) return;
        if (event.type == TelnetEventType.iac) {
          stateManager.handleCommand(event.bytes);

          // Check if TRANSMIT-BINARY was negotiated
          if (event.bytes.length >= 3 &&
              event.bytes[2] == NegotiationStateManager.transmitBinary) {
            int command = event.bytes[1];
            if (command == NegotiationStateManager.will) {
              // WILL
              completer.complete(
                AuditResult(
                  name,
                  AuditStatus.pass,
                  'Server supports Binary Mode (WILL BINARY).',
                ),
              );
            } else if (command == NegotiationStateManager.wont) {
              // WONT
              completer.complete(
                AuditResult(
                  name,
                  AuditStatus.pass,
                  'Server responded to Binary Mode request (WONT BINARY).',
                ),
              );
            }
          }
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.complete(
            AuditResult(
              name,
              AuditStatus.fail,
              'Error during binary mode probe: $error',
            ),
          );
        }
      },
    );

    try {
      stateManager.requestDo(NegotiationStateManager.transmitBinary);

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return AuditResult(
            name,
            AuditStatus.fail,
            'Timeout waiting for binary mode response.',
          );
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        return AuditResult(
          name,
          AuditStatus.fail,
          'Timeout waiting for binary mode response.',
        );
      }
      return AuditResult(
        name,
        AuditStatus.fail,
        'Exception during binary mode probe: $e',
      );
    } finally {
      await subscription.cancel();
    }
  }
}
