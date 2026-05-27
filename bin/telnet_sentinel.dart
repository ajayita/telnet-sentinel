import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:telnet_sentinel/telnet_sentinel.dart';

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

    final auditor = TelnetAuditor(host: host, port: port);
    final report = await auditor.runSuite(
      onLog: verbose && !outputJson ? (msg) => print('[VERBOSE] $msg') : null,
      onSnifferEvent: sniffer && !outputJson ? _printSnifferEvent : null,
    );

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

void _printSnifferEvent(TelnetEvent event) {
  if (event.type == TelnetEventType.iac) {
    final description = TelnetAuditor.describeIac(event.bytes);
    print('\x1B[36m[IAC] $description\x1B[0m'); // Cyan for IAC
  } else {
    final data = utf8.decode(event.bytes, allowMalformed: true);
    final escapedData = data.replaceAll('\r', '\\r').replaceAll('\n', '\\n');
    print('\x1B[32m[DATA] $escapedData\x1B[0m'); // Green for DATA
  }
}

void _printReport(AuditReport report) {
  print('\n--- Audit Report ---');
  print('Target:    ${report.target}');
  print('Timestamp: ${report.timestamp}');
  print('--------------------\n');

  for (final result in report.results) {
    final statusLabel = _getStatusLabel(result.status);
    final latencyStr = '${result.latency.inMilliseconds}ms';
    print('$statusLabel [${result.probeName}] ($latencyStr) ${result.message}');
    if (result.status == AuditStatus.fail &&
        result.rawBytesExchanged != null &&
        result.rawBytesExchanged!.isNotEmpty) {
      print('      Raw Bytes Exchanged: ${result.rawBytesExchanged}');
    }
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
