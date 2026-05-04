import 'dart:io';
import 'package:args/args.dart';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/probes/handshake_probe.dart';
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

    if (results.rest.isEmpty) {
      print('Error: No target host provided.');
      printUsage(argParser);
      exit(1);
    }

    final String host = results.rest.first;
    final int port = int.tryParse(results['port']) ?? 23;

    print('Starting audit for $host:$port...');

    RawSocket socket;
    try {
      socket = await RawSocket.connect(host, port, timeout: const Duration(seconds: 5));
    } catch (e) {
      print('Error: Could not connect to $host:$port - $e');
      exit(1);
    }

    final transport = TelnetTransport(socket);
    final probe = HandshakeProbe();
    final auditResults = <AuditResult>[];

    try {
      if (verbose) {
        print('[VERBOSE] Running HandshakeProbe...');
      }
      final result = await probe.run(transport);
      auditResults.add(result);
    } finally {
      await transport.close();
    }

    final report = AuditReport('$host:$port', auditResults);
    _printReport(report);

    if (report.hasFailures) {
      exit(1);
    }
  } on FormatException catch (e) {
    print(e.message);
    print('');
    printUsage(argParser);
    exit(1);
  } catch (e) {
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
