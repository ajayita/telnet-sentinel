import 'dart:async';

import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/models/telnet_event.dart';
import 'package:telnet_sentinel/src/state/negotiation_state_manager.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';
import 'package:telnet_sentinel/src/transport/gmcp_parser.dart';

class GmcpProbe implements Probe {
  static const int gmcp = 201;

  @override
  String get name => 'GMCP Probe';

  @override
  Future<AuditResult> run(TelnetTransport transport) async {
    final completer = Completer<AuditResult>();
    bool willReceived = false;

    final stateManager = NegotiationStateManager(
      onSend: (bytes) => transport.write(bytes),
    );

    final subscription = transport.events.listen(
      (event) {
        if (completer.isCompleted) return;

        if (event.type == TelnetEventType.iac) {
          final bytes = event.bytes;
          stateManager.handleCommand(bytes);

          // Check for WILL GMCP
          if (bytes.length == 3 &&
              bytes[0] == NegotiationStateManager.iac &&
              bytes[1] == NegotiationStateManager.will &&
              bytes[2] == gmcp) {
            willReceived = true;
          }

          // Check for WONT GMCP
          if (bytes.length == 3 &&
              bytes[0] == NegotiationStateManager.iac &&
              bytes[1] == NegotiationStateManager.wont &&
              bytes[2] == gmcp) {
            completer.complete(
              AuditResult(
                name,
                AuditStatus.fail,
                'Server refused GMCP (sent WONT GMCP).',
              ),
            );
          }

          // Check for IAC SB GMCP ... IAC SE
          if (bytes.length >= 5 &&
              bytes[0] == NegotiationStateManager.iac &&
              bytes[1] == NegotiationStateManager.sb &&
              bytes[2] == gmcp) {
            final gmcpEvent = GmcpParser.parse(bytes);
            if (gmcpEvent != null) {
              completer.complete(
                AuditResult(
                  name,
                  AuditStatus.pass,
                  'GMCP negotiation successful and valid GMCP message received: ${gmcpEvent.package}.${gmcpEvent.message}',
                ),
              );
            } else {
              completer.complete(
                AuditResult(
                  name,
                  AuditStatus.fail,
                  'Received malformed GMCP message.',
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
              'Error during GMCP probe: $error',
            ),
          );
        }
      },
    );

    try {
      // Request GMCP
      stateManager.requestDo(gmcp);

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          String reason = 'Timeout waiting for GMCP response.';
          if (willReceived) {
            reason =
                'Server sent WILL GMCP but did not send any GMCP subnegotiation messages.';
          }
          return AuditResult(name, AuditStatus.fail, reason);
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        String reason = 'Timeout waiting for GMCP response.';
        if (willReceived) {
          reason =
              'Server sent WILL GMCP but did not send any GMCP subnegotiation messages.';
        }
        return AuditResult(name, AuditStatus.fail, reason);
      }
      return AuditResult(
        name,
        AuditStatus.fail,
        'Exception during GMCP probe: $e',
      );
    } finally {
      await subscription.cancel();
    }
  }
}
