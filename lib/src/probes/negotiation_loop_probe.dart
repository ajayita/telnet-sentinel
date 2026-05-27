import 'dart:async';
import 'package:telnet_sentinel/src/transport/telnet_transport.dart';
import 'package:telnet_sentinel/src/models/audit_result.dart';
import 'package:telnet_sentinel/src/models/telnet_event.dart';
import 'package:telnet_sentinel/src/state/negotiation_state_manager.dart';
import 'package:telnet_sentinel/src/probes/probe_interface.dart';

class NegotiationLoopProbe implements Probe {
  @override
  String get name => 'Negotiation Loop Probe';

  @override
  Future<AuditResult> run(TelnetTransport transport) async {
    const int echoOption = 1;
    const int maxIterations = 5;
    int iterations = 0;
    final completer = Completer<AuditResult>();

    late final NegotiationStateManager stateManager;
    stateManager = NegotiationStateManager(
      onSend: (bytes) {
        transport.write(bytes);
      },
    );

    final subscription = transport.events.listen(
      (event) {
        if (completer.isCompleted) return;
        if (event.type == TelnetEventType.iac) {
          stateManager.handleCommand(event.bytes);

          // After state manager handles the command, check if we reached the desired state
          final currentState =
              stateManager.themStates[echoOption] ?? OptionState.no;

          if (iterations < maxIterations) {
            if (currentState == OptionState.yes) {
              // It's on, now turn it off
              stateManager.requestDont(echoOption);
            } else if (currentState == OptionState.no) {
              // It's off, now turn it on
              iterations++;
              if (iterations >= maxIterations) {
                if (!completer.isCompleted) {
                  completer.complete(
                    AuditResult(
                      name,
                      AuditStatus.pass,
                      'Successfully toggled negotiation $maxIterations times without issues.',
                    ),
                  );
                }
              } else {
                stateManager.requestDo(echoOption);
              }
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
              'Connection error during negotiation loop: $error',
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
              'Connection closed during negotiation loop.',
            ),
          );
        }
      },
    );

    try {
      // Start the loop by requesting DO ECHO
      stateManager.requestDo(echoOption);

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return AuditResult(
            name,
            AuditStatus.fail,
            'Timeout waiting for negotiation loop to complete. Iterations: $iterations',
          );
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        return AuditResult(
          name,
          AuditStatus.fail,
          'Timeout waiting for negotiation loop to complete. Iterations: $iterations',
        );
      }
      return AuditResult(
        name,
        AuditStatus.fail,
        'Exception during Negotiation Loop probe: $e',
      );
    } finally {
      await subscription.cancel();
    }
  }
}
