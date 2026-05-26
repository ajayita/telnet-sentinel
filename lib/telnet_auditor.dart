import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/models/telnet_event.dart';
import 'package:telnet_sentinel/models/audit_report.dart';
import 'package:telnet_sentinel/models/audit_result.dart';
import 'package:telnet_sentinel/probes/probe_interface.dart';
import 'package:telnet_sentinel/probes/handshake_probe.dart';
import 'package:telnet_sentinel/probes/ayt_probe.dart';
import 'package:telnet_sentinel/probes/binary_mode_probe.dart';
import 'package:telnet_sentinel/probes/gmcp_probe.dart';
import 'package:telnet_sentinel/probes/mccp_probe.dart';
import 'package:telnet_sentinel/probes/malformed_iac_probe.dart';
import 'package:telnet_sentinel/probes/negotiation_loop_probe.dart';

/// A high-level facade for executing diagnostic audits on a target Telnet server.
///
/// Encapsulates connection lifecycle, sequential probe scheduling, and reporting.
class TelnetAuditor {
  final String host;
  final int port;
  final Duration connectionTimeout;
  final List<Probe> probes;

  TelnetAuditor({
    required this.host,
    this.port = 23,
    this.connectionTimeout = const Duration(seconds: 5),
    List<Probe>? customProbes,
  }) : probes = customProbes ?? [
          HandshakeProbe(),
          AytProbe(),
          BinaryModeProbe(),
          GmcpProbe(),
          MccpProbe(),
          MalformedIacProbe(),
          NegotiationLoopProbe(),
        ];

  /// Runs the complete suite of Telnet probes.
  ///
  /// [verbose] triggers console logging of probe runs if set to true.
  /// [sniffer] prints a default color-coded real-time Telnet sequence dump.
  /// [onSnifferEvent] provides a hook for custom real-time traffic visualization.
  Future<AuditReport> runSuite({
    bool verbose = false,
    bool sniffer = false,
    void Function(TelnetEvent)? onSnifferEvent,
  }) async {
    final auditResults = <AuditResult>[];

    for (final probe in probes) {
      if (verbose) {
        print('[VERBOSE] Running ${probe.name}...');
      }

      RawSocket? socket;
      try {
        socket = await RawSocket.connect(
          host,
          port,
          timeout: connectionTimeout,
        );
        final transport = TelnetTransport(socket);

        StreamSubscription<TelnetEvent>? snifferSub;
        if (sniffer || onSnifferEvent != null) {
          snifferSub = transport.events.listen((event) {
            if (onSnifferEvent != null) {
              onSnifferEvent(event);
            } else if (sniffer) {
              _defaultSnifferPrint(event);
            }
          });
        }

        final result = await probe.run(transport);
        auditResults.add(result);

        if (snifferSub != null) {
          await snifferSub.cancel();
        }
        await transport.close();
      } catch (e) {
        auditResults.add(
          AuditResult(
            probe.name,
            AuditStatus.fail,
            'Connection/Execution error: $e',
          ),
        );
        if (socket != null) {
          socket.close();
        }
      }
    }

    return AuditReport('$host:$port', auditResults);
  }

  void _defaultSnifferPrint(TelnetEvent event) {
    if (event.type == TelnetEventType.iac) {
      final description = _describeIac(event.bytes);
      print('\x1B[36m[IAC] $description\x1B[0m'); // Cyan for IAC
    } else {
      final data = utf8.decode(event.bytes, allowMalformed: true);
      final escapedData = data
          .replaceAll('\r', '\\r')
          .replaceAll('\n', '\\n');
      print('\x1B[32m[DATA] $escapedData\x1B[0m'); // Green for DATA
    }
  }

  String _describeIac(List<int> bytes) {
    if (bytes.isEmpty) return 'EMPTY';
    if (bytes[0] != 255) return 'INVALID (not starting with IAC)';

    if (bytes.length == 1) return 'IAC';

    final command = bytes[1];
    String cmdStr;
    switch (command) {
      case 255:
        cmdStr = 'IAC';
        break;
      case 254:
        cmdStr = 'DONT';
        break;
      case 253:
        cmdStr = 'DO';
        break;
      case 252:
        cmdStr = 'WONT';
        break;
      case 251:
        cmdStr = 'WILL';
        break;
      case 250:
        cmdStr = 'SB';
        break;
      case 249:
        cmdStr = 'GA';
        break;
      case 248:
        cmdStr = 'EL';
        break;
      case 247:
        cmdStr = 'EC';
        break;
      case 246:
        cmdStr = 'AYT';
        break;
      case 245:
        cmdStr = 'AO';
        break;
      case 244:
        cmdStr = 'IP';
        break;
      case 243:
        cmdStr = 'BREAK';
        break;
      case 242:
        cmdStr = 'DM';
        break;
      case 241:
        cmdStr = 'NOP';
        break;
      case 240:
        cmdStr = 'SE';
        break;
      default:
        cmdStr = 'UNKNOWN($command)';
    }

    if (bytes.length == 2) return 'IAC $cmdStr';

    if (command >= 251 && command <= 254) {
      final option = bytes[2];
      String optStr;
      switch (option) {
        case 1:
          optStr = 'ECHO';
          break;
        case 3:
          optStr = 'SUPPRESS-GO-AHEAD';
          break;
        case 24:
          optStr = 'TERMINAL-TYPE';
          break;
        case 31:
          optStr = 'WINDOW-SIZE (NAWS)';
          break;
        case 32:
          optStr = 'TERMINAL-SPEED';
          break;
        case 33:
          optStr = 'REMOTE-FLOW-CONTROL';
          break;
        case 34:
          optStr = 'LINE-MODE';
          break;
        case 36:
          optStr = 'ENV-VAR';
          break;
        case 39:
          optStr = 'NEW-ENV-VAR';
          break;
        case 86:
          optStr = 'MCCP2';
          break;
        case 201:
          optStr = 'GMCP';
          break;
        default:
          optStr = 'OPTION($option)';
      }
      return 'IAC $cmdStr $optStr';
    }

    if (command == 250) {
      if (bytes.length < 5) return 'IAC SB ... (incomplete)';
      final option = bytes[2];
      String optStr;
      switch (option) {
        case 86:
          optStr = 'MCCP2';
          break;
        case 201:
          optStr = 'GMCP';
          break;
        default:
          optStr = 'OPTION($option)';
      }
      final content = bytes.sublist(3, bytes.length - 2);
      return 'IAC SB $optStr ${content.length} bytes IAC SE';
    }

    return 'IAC $cmdStr ${bytes.sublist(2)}';
  }
}
