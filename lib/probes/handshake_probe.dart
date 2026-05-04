import 'dart:async';
import 'dart:typed_data';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/models/audit_result.dart';
import 'package:telnet_sentinel/models/telnet_event.dart';
import 'package:telnet_sentinel/state/negotiation_state_manager.dart';
import 'probe_interface.dart';

class HandshakeProbe implements Probe {
  @override
  String get name => 'Handshake Audit';

  @override
  Future<AuditResult> run(TelnetTransport transport) async {
    final completer = Completer<AuditResult>();
    const int ttype = 24;

    final stateManager = NegotiationStateManager(
      onSend: (bytes) => transport.write(bytes),
    );

    final subscription = transport.events.listen((event) {
      if (event.type == TelnetEventType.iac) {
        stateManager.handleCommand(event.bytes);
        
        // Check if TTYPE was negotiated (either WILL or WONT)
        if (event.bytes.length >= 3 && event.bytes[2] == ttype) {
          int command = event.bytes[1];
          if (command == 251) { // WILL
             completer.complete(AuditResult(name, AuditStatus.pass, 'Server supports TTYPE negotiation (WILL).'));
          } else if (command == 252) { // WONT
             completer.complete(AuditResult(name, AuditStatus.pass, 'Server responded to TTYPE negotiation (WONT).'));
          }
        }
      }
    }, onError: (error) {
      if (!completer.isCompleted) {
        completer.complete(AuditResult(name, AuditStatus.fail, 'Error during handshake: $error'));
      }
    });

    try {
      stateManager.requestDo(ttype);

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return AuditResult(name, AuditStatus.fail, 'Timeout waiting for handshake response.');
        },
      );
    } catch (e) {
       if (e is TimeoutException) {
         return AuditResult(name, AuditStatus.fail, 'Timeout waiting for handshake response.');
       }
       return AuditResult(name, AuditStatus.fail, 'Exception during handshake: $e');
    } finally {
      await subscription.cancel();
    }
  }
}
