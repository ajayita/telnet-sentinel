import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/models/telnet_event.dart';
import 'package:telnet_sentinel/probes/probe_interface.dart';
import 'package:telnet_sentinel/probes/handshake_probe.dart';
import 'package:telnet_sentinel/probes/ayt_probe.dart';
import 'package:telnet_sentinel/probes/binary_mode_probe.dart';
import 'package:telnet_sentinel/probes/gmcp_probe.dart';
import 'package:telnet_sentinel/probes/mccp_probe.dart';
import 'package:telnet_sentinel/probes/malformed_iac_probe.dart';
import 'package:telnet_sentinel/probes/negotiation_loop_probe.dart';
import 'package:telnet_sentinel/models/audit_report.dart';
import 'package:telnet_sentinel/models/audit_result.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addOption(
      'port',
      abbr: 'p',
      defaultsTo: '23',
      help: 'The port to connect to.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'json',
      abbr: 'j',
      negatable: false,
      help: 'Output the report in JSON format.',
    )
    ..addFlag(
      'sniffer',
      abbr: 's',
      negatable: false,
      help: 'Visualize Telnet traffic in real-time.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.');
}

void printUsage(ArgParser argParser) {
  print('Usage: telnet_sentinel [flags] <host>');
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;
    bool outputJson = false;
    bool sniffer = false;

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      print('telnet_sentinel version: $version');
      return;
    }
    if (results.flag('verbose')) {
      verbose = true;
    }
    if (results.flag('json')) {
      outputJson = true;
    }
    if (results.flag('sniffer')) {
      sniffer = true;
    }

    if (results.rest.isEmpty) {
      if (!outputJson) {
        print('Error: No target host provided.');
        printUsage(argParser);
      }
      exit(1);
    }

    final String host = results.rest.first;
    final int port = int.tryParse(results['port']) ?? 23;

    if (!outputJson) {
      print('Starting audit for $host:$port...');
    }

    final probes = <Probe>[
      HandshakeProbe(),
      AytProbe(),
      BinaryModeProbe(),
      GmcpProbe(),
      MccpProbe(),
      MalformedIacProbe(),
      NegotiationLoopProbe(),
    ];

    RawSocket socket;
    try {
      socket = await RawSocket.connect(host, port, timeout: const Duration(seconds: 5));
    } catch (e) {
      if (!outputJson) {
        print('Error: Could not connect to $host:$port - $e');
      }
      exit(1);
    }

    final transport = TelnetTransport(socket);

    if (sniffer && !outputJson) {
      transport.events.listen((event) {
        if (event.type == TelnetEventType.iac) {
          final description = _describeIac(event.bytes);
          print('\x1B[36m[IAC] $description\x1B[0m'); // Cyan for IAC
        } else {
          final data = utf8.decode(event.bytes, allowMalformed: true);
          final escapedData = data.replaceAll('\r', '\\r').replaceAll('\n', '\\n');
          print('\x1B[32m[DATA] $escapedData\x1B[0m'); // Green for DATA
        }
      });
    }

    final probe = HandshakeProbe();
    final auditResults = <AuditResult>[];

    try {
      if (verbose && !outputJson) {
        print('[VERBOSE] Running HandshakeProbe...');
      }
      final result = await probe.run(transport);
      auditResults.add(result);
    } finally {
      await transport.close();
    }

    final report = AuditReport('$host:$port', auditResults);
    if (outputJson) {
      print(jsonEncode(report.toJson()));
    } else {
      _printReport(report);
    }

    if (report.hasFailures) {
      exit(1);
    }
  } on FormatException catch (e) {
    print(e.message);
    print('');
    printUsage(argParser);
    exit(1);
  } catch (e) {
    if (arguments.contains('--json') || arguments.contains('-j')) {
      // If we are in JSON mode, we should ideally output an error JSON, 
      // but for now just exit silently or with standard error message.
      // The requirement says output single JSON object containing full report.
    }
    print('An unexpected error occurred: $e');
    exit(1);
  }
}

void _printReport(AuditReport report) {
  print('\n--- Audit Report ---');
  print('Target:    ${report.target}');
  print('Timestamp: ${report.timestamp}');
  print('--------------------\n');

  for (final result in report.results) {
    final statusLabel = _getStatusLabel(result.status);
    print('$statusLabel [${result.probeName}] ${result.message}');
  }
  print('');

  if (report.hasFailures) {
    print('Audit COMPLETED with FAILURES.');
  } else {
    print('Audit COMPLETED successfully.');
  }
}

String _getStatusLabel(AuditStatus status) {
  switch (status) {
    case AuditStatus.pass:
      return '\x1B[32m[PASS]\x1B[0m'; // Green
    case AuditStatus.fail:
      return '\x1B[31m[FAIL]\x1B[0m'; // Red
    case AuditStatus.warning:
      return '\x1B[33m[WARN]\x1B[0m'; // Yellow
  }
}

String _describeIac(List<int> bytes) {
  if (bytes.isEmpty) return 'EMPTY';
  if (bytes[0] != 255) return 'INVALID (not starting with IAC)';

  if (bytes.length == 1) return 'IAC';

  final command = bytes[1];
  String cmdStr;
  switch (command) {
    case 255: cmdStr = 'IAC'; break;
    case 254: cmdStr = 'DONT'; break;
    case 253: cmdStr = 'DO'; break;
    case 252: cmdStr = 'WONT'; break;
    case 251: cmdStr = 'WILL'; break;
    case 250: cmdStr = 'SB'; break;
    case 249: cmdStr = 'GA'; break;
    case 248: cmdStr = 'EL'; break;
    case 247: cmdStr = 'EC'; break;
    case 246: cmdStr = 'AYT'; break;
    case 245: cmdStr = 'AO'; break;
    case 244: cmdStr = 'IP'; break;
    case 243: cmdStr = 'BREAK'; break;
    case 242: cmdStr = 'DM'; break;
    case 241: cmdStr = 'NOP'; break;
    case 240: cmdStr = 'SE'; break;
    default: cmdStr = 'UNKNOWN($command)';
  }

  if (bytes.length == 2) return 'IAC $cmdStr';

  if (command >= 251 && command <= 254) {
    final option = bytes[2];
    String optStr;
    switch (option) {
      case 1: optStr = 'ECHO'; break;
      case 3: optStr = 'SUPPRESS-GO-AHEAD'; break;
      case 24: optStr = 'TERMINAL-TYPE'; break;
      case 31: optStr = 'WINDOW-SIZE (NAWS)'; break;
      case 32: optStr = 'TERMINAL-SPEED'; break;
      case 33: optStr = 'REMOTE-FLOW-CONTROL'; break;
      case 34: optStr = 'LINE-MODE'; break;
      case 36: optStr = 'ENV-VAR'; break;
      case 39: optStr = 'NEW-ENV-VAR'; break;
      case 86: optStr = 'MCCP2'; break;
      case 201: optStr = 'GMCP'; break;
      default: optStr = 'OPTION($option)';
    }
    return 'IAC $cmdStr $optStr';
  }

  if (command == 250) { // SB
    if (bytes.length < 5) return 'IAC SB ... (incomplete)';
    final option = bytes[2];
    String optStr;
    switch (option) {
      case 86: optStr = 'MCCP2'; break;
      case 201: optStr = 'GMCP'; break;
      default: optStr = 'OPTION($option)';
    }
    final content = bytes.sublist(3, bytes.length - 2);
    return 'IAC SB $optStr ${content.length} bytes IAC SE';
  }

  return 'IAC $cmdStr ${bytes.sublist(2)}';
}
