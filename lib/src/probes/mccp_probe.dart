import 'dart:async';

import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/models/telnet_event.dart';
import 'package:telnet_sentinel/src/state/negotiation_state_manager.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';

class MccpProbe implements Probe {
  static const int mccp2 = 86;

  @override
  String get name => 'MCCP2 Probe';

  @override
  Future<AuditResult> run(TelnetTransport transport) async {
    final completer = Completer<AuditResult>();
    bool willReceived = false;
    bool sbReceived = false;

    final stateManager = NegotiationStateManager(
      onSend: (bytes) => transport.write(bytes),
    );

    final subscription = transport.events.listen(
      (event) {
        if (completer.isCompleted) return;

        if (event.type == TelnetEventType.iac) {
          final bytes = event.bytes;
          stateManager.handleCommand(bytes);

          // Check for WILL MCCP2
          if (bytes.length == 3 &&
              bytes[0] == NegotiationStateManager.iac &&
              bytes[1] == NegotiationStateManager.will &&
              bytes[2] == mccp2) {
            willReceived = true;
          }

          // Check for WONT MCCP2
          if (bytes.length == 3 &&
              bytes[0] == NegotiationStateManager.iac &&
              bytes[1] == NegotiationStateManager.wont &&
              bytes[2] == mccp2) {
            completer.complete(
              AuditResult(
                name,
                AuditStatus.fail,
                'Server refused MCCP2 (sent WONT MCCP2).',
              ),
            );
          }

          // Check for IAC SB MCCP2 IAC SE
          if (bytes.length == 5 &&
              bytes[0] == NegotiationStateManager.iac &&
              bytes[1] == NegotiationStateManager.sb &&
              bytes[2] == mccp2 &&
              bytes[3] == NegotiationStateManager.iac &&
              bytes[4] == NegotiationStateManager.se) {
            sbReceived = true;
          }
        } else if (event.type == TelnetEventType.data) {
          if (sbReceived) {
            completer.complete(
              AuditResult(
                name,
                AuditStatus.pass,
                'MCCP2 negotiation successful and compressed data received.',
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
              'Error during MCCP2 probe: $error',
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
              'Connection abruptly closed by server.',
            ),
          );
        }
      },
    );

    try {
      // Request MCCP2
      stateManager.requestDo(mccp2);

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          String reason = 'Timeout waiting for MCCP2 response.';
          if (willReceived && !sbReceived) {
            reason =
                'Server sent WILL MCCP2 but did not start compression (no SB MCCP2).';
          }
          return AuditResult(name, AuditStatus.fail, reason);
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        String reason = 'Timeout waiting for MCCP2 response.';
        if (willReceived && !sbReceived) {
          reason =
              'Server sent WILL MCCP2 but did not start compression (no SB MCCP2).';
        }
        return AuditResult(name, AuditStatus.fail, reason);
      }
      return AuditResult(
        name,
        AuditStatus.fail,
        'Exception during MCCP2 probe: $e',
      );
    } finally {
      await subscription.cancel();
    }
  }
}
